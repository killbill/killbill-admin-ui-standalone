#!/usr/bin/env python3
"""
Seed Kill Bill (and register the tenant in Kaui) with data for the Kaui load tests.

Only needs Python 3.8+ (standard library). Talks to Kill Bill's REST API and to Kaui's web UI.

What it creates, in the tenant given by --api-key/--api-secret:
  * the tenant itself (if missing) and the SpyCarAdvanced catalog (if the tenant has none)
  * --accounts "regular" accounts: default payment method, 1 subscription, a few external charges
    (so invoices + payments), a custom field and a tag
  * --large-accounts "large" accounts: same, but with --large-charges invoices/payments each, to exercise the
    pages that scale with account history (account page, timeline, invoices, payments)
  * the tenant in Kaui's own database (via Kaui's admin UI), so Kaui users can select it

It writes a CSV feeder for Gatling (default: ../gatling/src/test/resources/data/accounts.csv).

Re-running with the same --prefix reuses the accounts that already exist (looked up by external key).
"""
import argparse
import base64
import csv
import http.cookiejar
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = os.path.dirname(os.path.abspath(__file__))


class KillBill:
    def __init__(self, url, username, password, api_key, api_secret):
        self.url = url.rstrip('/')
        self.auth = 'Basic ' + base64.b64encode(f'{username}:{password}'.encode()).decode()
        self.api_key = api_key
        self.api_secret = api_secret

    def request(self, method, path, body=None, params=None, content_type='application/json', tenant=True, ok=(200, 201, 204)):
        url = self.url + path
        if params:
            url += '?' + urllib.parse.urlencode(params, doseq=True)
        headers = {
            'Authorization': self.auth,
            'Accept': 'application/json',
            'X-Killbill-CreatedBy': 'kaui-perf-seed',
        }
        if tenant:
            headers['X-Killbill-ApiKey'] = self.api_key
            headers['X-Killbill-ApiSecret'] = self.api_secret
        data = None
        if body is not None:
            data = body.encode() if isinstance(body, str) else json.dumps(body).encode()
            headers['Content-Type'] = content_type
        req = urllib.request.Request(url, data=data, method=method, headers=headers)
        for attempt in range(5):
            try:
                with urllib.request.urlopen(req, timeout=120) as resp:
                    raw = resp.read()
                    payload = json.loads(raw) if raw and resp.headers.get('Content-Type', '').startswith('application/json') else None
                    return resp.status, payload, resp.headers
            except urllib.error.HTTPError as e:
                if e.code in ok:
                    return e.code, None, e.headers
                if e.code >= 500 and attempt < 4:
                    time.sleep(2 ** attempt)
                    continue
                raise RuntimeError(f'{method} {path} -> {e.code}: {e.read().decode(errors="replace")[:500]}') from None
            except urllib.error.URLError:
                if attempt < 4:
                    time.sleep(2 ** attempt)
                    continue
                raise

    @staticmethod
    def id_from_location(headers):
        return headers['Location'].rstrip('/').split('/')[-1].split('?')[0]


def ensure_tenant(kb, name):
    try:
        kb.request('POST', '/1.0/kb/tenants', {'apiKey': kb.api_key, 'apiSecret': kb.api_secret, 'externalKey': name},
                   tenant=False, params={'useGlobalDefault': 'false'})
        print(f'Created tenant {kb.api_key}')
    except RuntimeError as e:
        if '409' not in str(e):
            raise
        print(f'Tenant {kb.api_key} already exists')
    _, tenant, _ = kb.request('GET', '/1.0/kb/tenants', params={'apiKey': kb.api_key}, tenant=False)
    return tenant['tenantId']


def ensure_catalog(kb, catalog_file):
    _, catalogs, _ = kb.request('GET', '/1.0/kb/catalog')
    if catalogs:
        print('Tenant already has a catalog')
        return
    with open(catalog_file) as f:
        kb.request('POST', '/1.0/kb/catalog/xml', f.read(), content_type='text/xml')
    print(f'Uploaded catalog {os.path.basename(catalog_file)}')


def ensure_tag_definition(kb, name):
    _, defs, _ = kb.request('GET', '/1.0/kb/tagDefinitions')
    for d in defs or []:
        if d['name'] == name:
            return d['id']
    _, _, headers = kb.request('POST', '/1.0/kb/tagDefinitions', {'name': name, 'description': 'Kaui load test data', 'applicableObjectTypes': ['ACCOUNT']})
    return KillBill.id_from_location(headers)


def find_account(kb, external_key):
    try:
        _, account, _ = kb.request('GET', '/1.0/kb/accounts', params={'externalKey': external_key})
        return account
    except RuntimeError as e:
        if '404' in str(e):
            return None
        raise


def seed_account(kb, prefix, profile, index, charges, plan, tag_def_id):
    """Create the account, or complete it if a previous (interrupted) run left it partially seeded."""
    external_key = f'{prefix}-{profile}-{index:05d}'
    account = find_account(kb, external_key)
    if account is None:
        _, _, headers = kb.request('POST', '/1.0/kb/accounts', {
            'externalKey': external_key,
            'name': f'Perf {profile.capitalize()} {index}',
            'email': f'{external_key}@example.com',
            'currency': 'USD',
            'country': 'US',
            'company': 'Kaui Perf',
        })
        account_id = KillBill.id_from_location(headers)
        account = {}
    else:
        account_id = account['accountId']

    if not account.get('paymentMethodId'):
        kb.request('POST', f'/1.0/kb/accounts/{account_id}/paymentMethods',
                   {'pluginName': '__EXTERNAL_PAYMENT__', 'externalKey': f'{external_key}-pm'}, params={'isDefault': 'true'})
    _, bundles, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/bundles')
    if not bundles:
        kb.request('POST', '/1.0/kb/subscriptions',
                   {'accountId': account_id, 'planName': plan, 'externalKey': f'{external_key}-sub'})
    _, fields, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/customFields')
    if not any(f['name'] == 'perf_profile' for f in fields or []):
        kb.request('POST', f'/1.0/kb/accounts/{account_id}/customFields', [{'name': 'perf_profile', 'value': profile}])
    _, tags, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/tags')
    if not any(t['tagDefinitionId'] == tag_def_id for t in tags or []):
        kb.request('POST', f'/1.0/kb/accounts/{account_id}/tags', [tag_def_id])

    # External charges: one invoice each ...
    # (count invoices, not charges: the account invoice list doesn't return items. Recurring invoices generated later
    # by the subscription only make us add fewer charges, never duplicate them.)
    _, invoices, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/invoices')
    existing = len(invoices or [])
    for n in range(existing, charges):
        kb.request('POST', f'/1.0/kb/invoices/charges/{account_id}',
                   [{'accountId': account_id, 'amount': 10 + (n % 90), 'currency': 'USD', 'description': f'perf charge {n}'}],
                   params={'autoCommit': 'true'})
    # ...then pay whatever is unpaid (one payment per invoice) with the default (external) payment method
    _, account, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}', params={'accountWithBalance': 'true'})
    if float(account.get('accountBalance') or 0) > 0:
        kb.request('POST', f'/1.0/kb/accounts/{account_id}/invoicePayments', params={'externalPayment': 'false'})

    _, bundles, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/bundles')
    _, invoices, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/invoices')
    _, payments, _ = kb.request('GET', f'/1.0/kb/accounts/{account_id}/payments')
    bundle = (bundles or [{}])[0]
    subscription = (bundle.get('subscriptions') or [{}])[0]
    return {
        'account_id': account_id,
        'external_key': external_key,
        'profile': profile,
        'bundle_id': bundle.get('bundleId', ''),
        'subscription_id': subscription.get('subscriptionId', ''),
        'invoice_id': (invoices or [{}])[-1].get('invoiceId', ''),
        'payment_id': (payments or [{}])[-1].get('paymentId', ''),
        'nb_invoices': len(invoices or []),
        'nb_payments': len(payments or []),
    }


def register_tenant_in_kaui(kaui_url, username, password, name, api_key, api_secret):
    """Go through Kaui's UI (login, then the 'new tenant' form), the same way an admin would."""
    jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    base = kaui_url.rstrip('/')

    def csrf(path):
        with opener.open(base + path, timeout=120) as resp:
            html = resp.read().decode()
        m = re.search(r'name="authenticity_token" value="([^"]+)"', html) or re.search(r'name="csrf-token" content="([^"]+)"', html)
        if not m:
            raise RuntimeError(f'No CSRF token on {path} (is Kaui up at {base}?)')
        return m.group(1)

    def post(path, fields):
        data = urllib.parse.urlencode(fields).encode()
        with opener.open(urllib.request.Request(base + path, data=data, method='POST'), timeout=120) as resp:
            return resp.geturl(), resp.read().decode()

    token = csrf('/users/sign_in')
    final_url, _ = post('/users/sign_in', {'authenticity_token': token, 'user[kb_username]': username, 'user[password]': password})
    if '/users/sign_in' in final_url:
        raise RuntimeError(f'Kaui login failed for {username}')

    token = csrf('/admin_tenants/new')
    final_url, html = post('/admin_tenants', {'authenticity_token': token, 'tenant[name]': name,
                                              'tenant[api_key]': api_key, 'tenant[api_secret]': api_secret})
    # New tenant: Kaui redirects to /admin_tenants/<id>. Tenant already configured: Kaui redirects to the tenant's page,
    # which (no tenant selected yet in this session) bounces through tenant selection to the home page.
    path = urllib.parse.urlparse(final_url).path
    if not (re.search(r'/admin_tenants/\d+$', path) or path.endswith('/home') or path.endswith('/')):
        raise RuntimeError(f'Unexpected response registering tenant in Kaui (ended at {final_url})')
    print(f'Tenant {name} is configured in Kaui')


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--killbill-url', default=os.environ.get('KILLBILL_URL', 'http://127.0.0.1:8080'))
    p.add_argument('--kaui-url', default=os.environ.get('KAUI_URL', 'http://127.0.0.1:9090'),
                   help='Kaui base URL, including the context path if not deployed at / (e.g. http://host:8080/kaui)')
    p.add_argument('--username', default=os.environ.get('KB_USERNAME', 'admin'))
    p.add_argument('--password', default=os.environ.get('KB_PASSWORD', 'password'))
    p.add_argument('--tenant-name', default='perf')
    p.add_argument('--api-key', default=os.environ.get('KB_API_KEY', 'perf'))
    p.add_argument('--api-secret', default=os.environ.get('KB_API_SECRET', 'perf-secret'))
    p.add_argument('--catalog', default=os.path.join(HERE, 'SpyCarAdvanced.xml'))
    p.add_argument('--plan', default='sports-monthly')
    p.add_argument('--prefix', default='perf', help='external key prefix for the accounts created')
    p.add_argument('--accounts', type=int, default=200, help='number of regular accounts')
    p.add_argument('--charges', type=int, default=3, help='invoices/payments per regular account')
    p.add_argument('--large-accounts', type=int, default=5, help='number of large accounts')
    p.add_argument('--large-charges', type=int, default=300, help='invoices/payments per large account')
    p.add_argument('--threads', type=int, default=8)
    p.add_argument('--skip-kaui', action='store_true', help='do not register the tenant in Kaui')
    p.add_argument('--output', default=os.path.join(HERE, '..', 'gatling', 'src', 'test', 'resources', 'data', 'accounts.csv'))
    args = p.parse_args()

    kb = KillBill(args.killbill_url, args.username, args.password, args.api_key, args.api_secret)
    kb_tenant_id = ensure_tenant(kb, args.tenant_name)
    ensure_catalog(kb, args.catalog)
    tag_def_id = ensure_tag_definition(kb, 'perf')

    jobs = [('regular', i, args.charges) for i in range(args.accounts)] + \
           [('large', i, args.large_charges) for i in range(args.large_accounts)]
    rows = []
    started = time.time()
    with ThreadPoolExecutor(max_workers=args.threads) as pool:
        futures = [pool.submit(seed_account, kb, args.prefix, profile, i, charges, args.plan, tag_def_id) for profile, i, charges in jobs]
        for n, future in enumerate(as_completed(futures), 1):
            rows.append({'kb_tenant_id': kb_tenant_id, **future.result()})
            if n % 25 == 0 or n == len(futures):
                print(f'  {n}/{len(futures)} accounts ready ({time.time() - started:.0f}s)')

    rows.sort(key=lambda r: r['external_key'])
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f'Wrote {len(rows)} accounts to {os.path.abspath(args.output)}')

    if not args.skip_kaui:
        register_tenant_in_kaui(args.kaui_url, args.username, args.password, args.tenant_name, args.api_key, args.api_secret)


if __name__ == '__main__':
    try:
        main()
    except RuntimeError as e:
        sys.exit(f'ERROR: {e}')
