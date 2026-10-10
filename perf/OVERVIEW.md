# Kaui: overview for performance work

## What Kaui is

Kaui is the admin UI of [Kill Bill](https://killbill.io), the open-source billing platform. It is a **Rails 7.2**
application that runs on **JRuby 10** inside **Tomcat 11** (JDK 21), packaged as a WAR by Warbler.

```
Browser ──HTTP──► Tomcat 11 (JDK 21)
                   └─ kaui-standalone.war            (killbill-admin-ui-standalone: thin Rails host app)
                       └─ jruby-rack 2.0, 1 shared thread-safe JRuby runtime
                           ├─ Kaui engine            (killbill-admin-ui: controllers, views, models)
                           ├─ 7 more engines         (Kanaui analytics, Aviate, KPM, Deposit, Avatax, Kenui, PaymentTest)
                           ├─ Devise/Warden + CanCan (auth, permissions)
                           └─ killbill-client gem ──HTTP/JSON (Net::HTTP)──► Kill Bill server (Java)
                  ActiveRecord (activerecord-jdbc) ──► MySQL/MariaDB `kaui` db (users, tenants only)
```

Almost all of Kaui's data lives in Kill Bill: every page is a set of REST calls to Kill Bill, turned into Ruby objects,
then rendered with ERB. Kaui's own database only holds users, tenants and which user can see which tenant.

So the JRuby work per request is: Rack/Rails/Devise middleware, JSON parsing and model building (killbill-client),
view rendering, and the glue that fans Kill Bill calls out to threads (`concurrent-ruby` futures). The time *waiting*
on Kill Bill is IO and largely outside JRuby's control; we are mostly interested in what happens around it.

| Repository | What | Notes |
|---|---|---|
| [killbill-admin-ui](https://github.com/killbill/killbill-admin-ui) | the Kaui engine (gem `kaui`) | all the application code |
| [killbill-admin-ui-standalone](https://github.com/killbill/killbill-admin-ui-standalone) | the deployable WAR | Gemfile, Warbler config, logback, engine mounts. This harness lives here |
| [killbill-client-ruby](https://github.com/killbill/killbill-client-ruby) | gem `killbill-client` | HTTP client + models for Kill Bill's API |
| [killbill-cloud](https://github.com/killbill/killbill-cloud/tree/java2x) (`java2x`) | Docker images / Ansible | Tomcat `server.xml`, JVM flags (`setenv.sh`) |

## Deployment topologies

We run Kaui in both of these setups, and performance/behavior should be verified in **both**:

| | A. Separate Tomcats | B. Shared Tomcat |
|---|---|---|
| Layout | Kaui in its own Tomcat/JVM; Kill Bill in another (same or different host) | Kill Bill (`/`) and Kaui (`/kaui`) WARs in **one** Tomcat/JVM |
| Kaui → Kill Bill | HTTP over the network | HTTP over loopback, **into the same Tomcat** |
| Shared | nothing | heap and GC, CPU, the Tomcat request thread pool (100 threads), JVM flags |

What topology B changes, and why it matters:

* A Kaui request holds a Tomcat thread while it waits for its Kill Bill calls, and those calls need Tomcat threads
  from **the same pool**. The account page alone fans out ~12 Kill Bill calls in parallel. Under load, Kaui requests
  can starve Kill Bill of threads (latency cliffs, timeouts, in the worst case a deadlock-like stall until the 60s
  client timeout).
* GC pauses and allocation pressure from one application hit the other. Kill Bill is also a big Java application.
* JVM flags are shared: `-Djruby.compile.invokedynamic=false` (see below) applies to both.

## Anatomy of a Kaui request

Every authenticated page pays this before doing its own work (killbill-admin-ui `master`):

1. **Warden `after_set_user` hook**: `GET /1.0/kb/security/subject` on Kill Bill to check the Kill Bill session is still
   valid (`config/initializers/killbill_authenticatable.rb:76`). One HTTP call per request.
2. **CanCan permissions**: the navbar calls `can?`, which builds `Kaui::Ability`, which calls
   `GET /1.0/kb/security/permissions` (`app/models/kaui/user.rb:21`, `app/models/kaui/ability.rb`). Another HTTP call.
3. **Tenant check**: `Kaui::AllowedUser` + tenants query on every request (`lib/kaui.rb:276`).
4. **Kill Bill client options**: `options_for_klient` looks up the tenant and decrypts its API secret
   (symmetric-encryption) on every call (`lib/kaui.rb:296`). Some controllers cache it per request, some don't.
5. **`populate_account_details` before-action**: pages under `/accounts/:id` fetch the account
   (`app/controllers/kaui/engine_controller.rb:42`); the account page then fetches it again with balance and CBA
   (`accounts_controller.rb:109`).
6. **No HTTP connection reuse**: killbill-client opens a new TCP connection for every call
   (`Net::HTTP.new` + `start` per request in `killbill_client/api/net_http_adapter.rb`).
7. **No caching**: nothing uses `Rails.cache`; catalog, tag definitions and permissions are fetched every time.

### Concurrency model

* Tomcat: 100 request threads (`TOMCAT_MAX_THREADS`), all running in **one shared JRuby runtime** (Warbler's default
  for Rails >= 4; the log says `using a shared (thread-safe) runtime`).
* Inside a request, Kaui parallelizes Kill Bill calls with `concurrent-ruby` futures (`promise`/`wait` in
  `app/controllers/kaui/engine_controller_util.rb:111`). They run on concurrent-ruby's **global, unbounded** IO pool;
  the bounded pool Kaui defines (`Kaui.thread_pool`, 10-50 threads, `lib/kaui/engine.rb:42`) is never used. Each
  future is wrapped in `Rails.application.executor.wrap`.
* ActiveRecord pool: 50 (`KAUI_DB_POOL`).

## What we would like to improve

In order of interest:

1. **Latency of the heavy pages** (p95/p99), especially on accounts with a long history:
   account page (`accounts#show`), timeline (`account_timelines#show`), invoices/payments lists (DataTables JSON,
   sorted in Ruby in `paginate`), subscription pages (catalog fetched and parsed every time).
2. **Throughput and behavior under concurrency** in the shared runtime: thread usage (Tomcat threads + unbounded
   future threads), contention, and how it degrades in topology B.
3. **Allocation**: JSON → killbill-client model hydration (large timeline / invoice payloads), view rendering, the
   per-request fixed cost above.
4. **JRuby/JVM configuration**: invokedynamic is disabled, JIT behavior (see Known issues), heap/GC settings.

Candidates for isolated benchmarks (command line, no server), using recorded Kill Bill JSON responses:

* `KillBillClient::Model::AccountTimeline` / `Invoice` / `Payment` `from_json` on a large account's payloads
* `Kaui::Catalog` JSON processing for the subscription pages
* `paginate` + formatters (`engine_controller_util.rb`) on 50-row pages
* rendering `kaui/accounts/show` with stubbed data
* the per-request auth stack (Devise/Warden + `Kaui::Ability`) with Kill Bill stubbed

## Configuration as shipped

From killbill-cloud `java2x` (`ansible/templates/tomcat/conf/setenv.sh.j2`, `server.xml.j2`, `group_vars/all.yml`),
reproduced in `perf/tomcat/`:

| Setting | Value | Comment |
|---|---|---|
| `-Djruby.compile.invokedynamic=false` | set | disables JRuby's indy optimizations; was there for Kill Bill's old JRuby plugins. Worth measuring with `true` |
| `-Xrunjdwp:...,server=y,suspend=n` | always on | debugger agent in production |
| `-Xlog:gc*=debug,safepoint*=debug,age*=debug` | on by default | verbose GC logging (useful for you; `TOMCAT_DISABLE_GC_LOGGING` turns it off) |
| `-Xms512m -Xmx2G`, G1, `SurvivorRatio=10` | | 8 Rails engines + JSON-heavy pages in 2G |
| `-XX:+ScavengeBeforeFullGC` | | obsolete on JDK 21 (ignored) |
| `-Dlog4jdbc.sqltiming.error.threshold=${JVM_JMX_PORT:-1000}` | | template bug: uses the JMX port variable (harmless for Kaui) |
| JMX `:8000`, no auth | | handy for profilers |
| Tomcat `maxThreads=100`, `minSpareThreads=4` | | NIO connector, `connectionTimeout=20000` |
| Access log | `%h %l %u %t "%m %U" %s %b %D %{X-Request-id}i` | `%D` is **microseconds** on Tomcat 10.1+ |
| Logging | logback, INFO, file + stdout (JSON on stdout in the Docker image), synchronous appenders | 5 MDC keys set per request |

## Known issues

### 1. Logins fail once JRuby's JIT has compiled `Rails::Engine#call` (blocker)

Found while building this harness, on kaui-standalone 5.0.2 (Kaui 4.0.27, Rails/railties 7.2.4, rack 2.2.24,
jruby-rack 2.0) / JRuby 10.0.6.0 / OpenJDK 21.0.12 / Tomcat 11.0.26, with the production JVM flags:

* After ~10-20 requests (any pages, even sequential from a single user), `GET /users/sign_in` stops returning a
  `Set-Cookie` header, for everyone, until Tomcat restarts. Without a session the login form's CSRF token can't be
  verified (`Can't verify CSRF token authenticity`), so `POST /users/sign_in` returns 401 and **nobody can log in any
  more**. Users who already have a session cookie keep working.
* Same with `-Djruby.compile.invokedynamic=true`. Doesn't happen with `-Djruby.compile.mode=OFF`.
* Bisected with `-Djruby.jit.exclude` over the ~550 classes the JIT compiles, down to the `Rails::Engine` class, then
  to one method: excluding **`Rails::Engine#call`** alone makes it go away; excluding `Rails::Engine#build_request`
  doesn't. (Method exclusions use the `Class#method` syntax.)
* `Rails::Engine#call` (railties 7.2.4, `lib/rails/engine.rb:532`) is `req = build_request(env); app.call(req.env)`.
  `Rails::Application` (the receiver for the main app) overrides `build_request`, and `env_config`, which is where the
  secret key base / cookie configuration comes from, while mounted engines (Kaui and the 7 others) use the
  `Rails::Engine` versions. Our guess: once compiled, the call site dispatches to the wrong implementation for the
  application, the request env lacks the cookie configuration, and the session cookie is silently not written.
  Not verified further.
* **Workaround**: `-Djruby.jit.exclude=Rails::Engine#call` (e.g. `KAUI_SYSTEM_PROPERTIES`). With it, a 150s mixed run
  (31 logins, 866 requests) had no errors and the cookie was still issued at the end.

Reproduce:

```bash
cookie() { curl -s -D - -o /dev/null http://localhost:9090/users/sign_in | grep -ci set-cookie; }
cookie                                   # 1 on a fresh Tomcat
# log in once, then load any account page ~20 times
cookie                                   # 0 from now on (1 with the workaround)
```

Secondary bug seen at the same time: when the login fails, Devise's failure app re-renders the login page and raises
`Could not find devise mapping for path "/users/sign_in"` (HTTP 500 instead of the login form with an error).

## First numbers (indicative only)

Topology A, production flags + the workaround above, `mix` scenario, 10 users, 0.5-1.5s think time, 150s, data from
`seed.py` defaults. **Not representative hardware**: one 4-vCPU / 15 GB VM running Kaui, Kill Bill 0.24.22 and
MariaDB (Docker) and Gatling. Server-side times from Tomcat's access log:

| Request | n | p50 (ms) | p95 (ms) | max (ms) |
|---|---|---|---|---|
| `GET /accounts/:id/timeline` | 50 | 1427 | 7127 | 9195 |
| `GET /payments/pagination.json` | 53 | 568 | 4360 | 9079 |
| `GET /accounts/:id` | 147 | 2809 | 4025 | 5465 |
| `GET /accounts/:id/invoices/:id` | 36 | 1968 | 2817 | 3267 |
| `GET /accounts/:id/bundles` | 21 | 1724 | 2415 | 2440 |
| `GET /accounts/:id/payments/:id` | 40 | 1404 | 2354 | 2522 |
| `GET /home` | 24 | 1278 | 1761 | 2138 |
| `GET /accounts/:id/payments` | 53 | 1041 | 1666 | 2383 |
| `GET /accounts/:id/invoices` | 80 | 872 | 1648 | 2200 |
| `GET /invoices/pagination.json` | 80 | 624 | 1394 | 2875 |
| `GET /subscriptions/:id/edit` | 21 | 627 | 1171 | 1508 |
| `GET /accounts` | 72 | 465 | 884 | 1239 |
| `POST /accounts/pagination.json` | 71 | 356 | 755 | 891 |
| `POST /users/sign_in` | 23 | 173 | 311 | 380 |

Even at 10 users, the account page and the timeline take seconds. The large accounts (300 invoices/payments) drive the
tails.

## Profiling hooks

* JMX on `:8000` (VisualVM, JMC). JFR:
  `jcmd <pid> JFR.start name=kaui settings=profile duration=300s filename=/tmp/kaui.jfr`
* async-profiler works against the Tomcat PID (`-e cpu`, `-e alloc`, `-e lock`).
* JRuby: `-Djruby.jit.logging=true` (what gets compiled), `-Djruby.compile.mode=OFF` (interpreter only) via
  `KAUI_SYSTEM_PROPERTIES`.
* Correlation: Gatling sends a random `X-Request-Id` on every request; it appears in Kaui's logs (`rId=`), is
  forwarded to Kill Bill, and is in Tomcat's access log next to the server-side duration.
