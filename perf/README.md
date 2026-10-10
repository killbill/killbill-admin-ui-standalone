# Kaui load tests

Load-test harness for Kaui (`kaui-standalone` WAR) running the way it runs in production:
**JRuby 10 + Tomcat 11 + JDK 21**, configured from [killbill-cloud@java2x](https://github.com/killbill/killbill-cloud/tree/java2x).

For what Kaui is, where the JRuby parts are, and what we would like to improve, read [OVERVIEW.md](OVERVIEW.md) first.

```
perf/
├── OVERVIEW.md                  application overview, topologies, known hotspots, findings (for the performance team)
├── tomcat/                      Tomcat CATALINA_BASE matching production (rendered from killbill-cloud@java2x)
│   ├── setup-catalina-base.sh   creates a CATALINA_BASE and deploys the WAR(s)
│   ├── conf/                    server.xml, context.xml, web.xml
│   └── bin/                     setenv.sh (JVM flags), setenv2.sh (Kaui)
├── seed/seed.py                 creates test data in Kill Bill + registers the tenant in Kaui, writes the Gatling feeder
└── gatling/                     Gatling project (Java DSL), ./mvnw gatling:test
```

Versions used: `kaui-standalone` **5.0.2** (Kaui 4.0.27, JRuby 10.0.6.0, jruby-rack 2.0, Rails 7.2), Tomcat **11.0.x**,
JDK **21**, Gatling **3.16.0**.

> [!WARNING]
> With kaui-standalone 5.0.2 and JRuby's JIT on (the default), Kaui stops issuing session cookies after ~10-20
> requests, so **every login after warm-up fails** (logged-in sessions keep working). The cause is the JIT-compiled
> `Rails::Engine#call`. Until it is fixed, start Kaui with
> `KAUI_SYSTEM_PROPERTIES=-Djruby.jit.exclude=Rails::Engine#call` (see [OVERVIEW.md, Known issues](OVERVIEW.md#known-issues)).

## 1. Prerequisites

On the machine running Kaui (no Docker needed):

| What | Notes |
|---|---|
| JDK 21 | e.g. `apt install openjdk-21-jdk-headless` |
| Tomcat 11.0.x | download from <https://tomcat.apache.org/download-11.cgi>, unpack anywhere (`CATALINA_HOME`) |
| `kaui-standalone-5.0.2.war` | <https://repo1.maven.org/maven2/org/kill-bill/billing/kaui/kaui-standalone/5.0.2/kaui-standalone-5.0.2.war> |
| MySQL/MariaDB | a `kaui` database with [Kaui's schema](https://github.com/killbill/killbill-admin-ui/blob/master/db/ddl.sql) (plus a `killbill` database for Kill Bill) |
| Kill Bill | see topologies below |

On the machine running Gatling: **JDK 17+ only** (21 is fine). `./mvnw` downloads Maven, Gatling and its plugin on
first use, so it needs access to Maven Central (or your mirror) once. Python 3.8+ for the seed script (standard library
only).

Run Gatling on a **different machine** than Kaui when you can: Gatling is CPU hungry and would skew the profiles.
If you only have one server, pin them to different cores (`taskset -c 0-3 catalina.sh run`, `taskset -c 4-5 ./mvnw ...`).

Production installs the same thing with Ansible (`ansible/java.yml`, `tomcat.yml`, `kaui.yml` from killbill-cloud on
the `java2x` branch). `tomcat/` here is a rendering of the same templates, so you don't need Ansible to reproduce it.

## 2. Deploy Kaui: the two topologies

We run Kaui both ways in production, and **both should be measured**: they compete for different resources
(see [OVERVIEW.md](OVERVIEW.md#deployment-topologies)).

### A. Separate Tomcats (Kaui alone)

```bash
perf/tomcat/setup-catalina-base.sh -h $CATALINA_HOME -b /opt/kaui-base -k kaui-standalone-5.0.2.war
```

Kill Bill runs elsewhere (another Tomcat, another host, or `docker run killbill/killbill:0.24.22`).

### B. Shared Tomcat (Kill Bill + Kaui in the same JVM)

```bash
perf/tomcat/setup-catalina-base.sh -h $CATALINA_HOME -b /opt/kb-base \
  -K killbill-profiles-killbill-<version>.war \
  -k kaui-standalone-5.0.2.war:kaui
```

Kill Bill is deployed at `/`, Kaui at `/kaui` (we checked that Kaui 5.0.2 runs under `/kaui`: links, assets and the
Gatling scenarios all work with `-Dkaui.baseUrl=http://host:port/kaui`). Kill Bill must be a version that runs on Tomcat 11 / JDK 21
(Jakarta Servlet); check with the core team which one (the 0.24.x `killbill/killbill` images are still Tomcat 9 /
JDK 11). Kill Bill's own settings go in its usual `killbill.properties` / `-Dorg.killbill.*` system properties.

### Start Tomcat

Same environment variables as the production images (all optional except the database/Kill Bill ones):

```bash
export CATALINA_HOME=/opt/apache-tomcat-11.0.26 CATALINA_BASE=/opt/kaui-base

# Kaui
export KAUI_KILLBILL_URL=http://127.0.0.1:8080          # Kill Bill (for B: the same Tomcat)
export KAUI_DB_URL='jdbc:mysql://127.0.0.1:3306/kaui?useUnicode=true&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=UTC&allowPublicKeyRetrieval=true'
export KAUI_DB_USERNAME=root KAUI_DB_PASSWORD=...
export KAUI_ROOT_USERNAME=admin                          # Kill Bill user allowed to create tenants in Kaui

# Workaround for the JIT issue above (KAUI_SYSTEM_PROPERTIES is appended to CATALINA_OPTS by setenv2.sh)
export KAUI_SYSTEM_PROPERTIES='-Djruby.jit.exclude=Rails::Engine#call'

# Tomcat / JVM (defaults from killbill-cloud group_vars)
export TOMCAT_PORT=9090                                  # default 8080
export TOMCAT_MAX_THREADS=100 TOMCAT_JAVA_XMS=512m TOMCAT_JAVA_XMX=2G

$CATALINA_HOME/bin/catalina.sh run
```

Kaui takes ~20-25s to deploy. `GET /users/sign_in` returning 200 means it is up.

## 3. Seed test data

```bash
python3 perf/seed/seed.py \
  --killbill-url http://127.0.0.1:8080 \
  --kaui-url http://127.0.0.1:9090 \
  --username admin --password password \
  --accounts 200 --charges 3 \
  --large-accounts 5 --large-charges 300
```

For topology B, `--kaui-url` includes the context path: `http://host:8080/kaui`.

It creates (idempotently, keyed on `--prefix`) a tenant (`perf` / `perf-secret`), the SpyCarAdvanced catalog,
regular accounts (3 paid invoices each) and a few large accounts (300 paid invoices each, which is what makes the
account, timeline, invoices and payments pages heavy), registers the tenant in Kaui, and writes the Gatling feeder to
`perf/gatling/src/test/resources/data/accounts.csv`. 200 + 5 accounts take ~2 minutes. Re-running it completes
partially seeded accounts and adds nothing to complete ones.

## 4. Run Gatling

```bash
cd perf/gatling
./mvnw gatling:test -Dkaui.baseUrl=http://kaui-host:9090 -Dkaui.users=20 -Dkaui.durationSeconds=600
```

The HTML report is written to `target/gatling/kauisimulation-<timestamp>/index.html`. The run fails (non-zero exit)
when more than `kaui.maxErrorPct` % of the requests fail.

Each virtual user logs in, selects the tenant, browses `kaui.iterations` pages (one account per page, think time in
between), then leaves and is replaced by a new one: `kaui.users` users are active at any time (closed model, like a team
of admins).

| Setting (`-Dkaui.x` or `KAUI_X`) | Default | |
|---|---|---|
| `baseUrl` | `http://127.0.0.1:9090` | include the context path for topology B, e.g. `http://host:8080/kaui` |
| `username` / `password` | `admin` / `password` | Kill Bill credentials used to log in to Kaui |
| `accountsFile` | `data/accounts.csv` | feeder written by `seed.py` (classpath or file path) |
| `scenario` | `mix` | `mix`, or one page to hammer in isolation (see below) |
| `users` | `10` | concurrent users |
| `rampSeconds` / `durationSeconds` | `30` / `300` | ramp-up, then steady state |
| `iterations` | `20` | pages per user session (raise it to reduce the share of logins) |
| `thinkMinMs` / `thinkMaxMs` | `1000` / `3000` | think time between pages; `0`/`0` for a stress test |
| `largeAccountPct` | `10` | % of pages done on a large account |
| `fetchResources` | `false` | also fetch CSS/JS/images (served by Tomcat, not Rails) |
| `maxErrorPct` | `1` | assertion on the global error rate |

`kaui.scenario` values (also the request names in the report):

| Scenario | Requests | Weight in `mix` |
|---|---|---|
| `account_show` | `GET /accounts/:id` (account page: ~12 parallel Kill Bill calls) | 25% |
| `account_search` | `GET /accounts` + `POST /accounts/pagination.json` | 15% |
| `invoices` | `GET /accounts/:id/invoices` + `GET /invoices/pagination.json` | 15% |
| `payments` | `GET /accounts/:id/payments` + `GET /payments/pagination.json` | 10% |
| `timeline` | `GET /accounts/:id/timeline` (full audit history) | 10% |
| `invoice_show` | `GET /accounts/:id/invoices/:invoice_id` | 8% |
| `payment_show` | `GET /accounts/:id/payments/:payment_id` | 7% |
| `subscription_edit` | `GET /subscriptions/:id/edit` (catalog) | 5% |
| `bundles` | `GET /accounts/:id/bundles` | 5% |
| `home` | `GET /home` | only as a single scenario |

Examples:

```bash
# Baseline: realistic mix, 20 admins
./mvnw gatling:test -Dkaui.users=20

# Stress: no think time, find the throughput ceiling
./mvnw gatling:test -Dkaui.users=50 -Dkaui.thinkMinMs=0 -Dkaui.thinkMaxMs=0

# Profile one page in isolation, large accounts only
./mvnw gatling:test -Dkaui.scenario=timeline -Dkaui.largeAccountPct=100 -Dkaui.users=10 -Dkaui.thinkMaxMs=0
```

Every request carries a random `X-Request-Id`. Kaui logs it (`rId=` in its logs), passes it to Kill Bill, and Tomcat's
access log records it next to the server-side duration, so a slow request in the Gatling report can be traced end to
end. Note: in Tomcat 10.1+ the access log's `%D` is in **microseconds**.

## 5. Tuning knobs

| Layer | Knob | Default | Where |
|---|---|---|---|
| Tomcat | request threads | 100 | `TOMCAT_MAX_THREADS` |
| JVM | heap | 512m / 2G | `TOMCAT_JAVA_XMS` / `TOMCAT_JAVA_XMX` |
| JVM | GC log (debug level, `logs/gc.log`) | on | `TOMCAT_DISABLE_GC_LOGGING=1` to turn off |
| JVM | any other flag | | `CATALINA_OPTS`, or `KAUI_SYSTEM_PROPERTIES` (appended last by `setenv2.sh`, so it wins) |
| JRuby | invokedynamic | **off** (`-Djruby.compile.invokedynamic=false` in `setenv.sh`) | add `-Djruby.compile.invokedynamic=true` to `KAUI_SYSTEM_PROPERTIES` (space-separated, keep the workaround) |
| JRuby | runtimes | 1 shared, thread-safe runtime (Warbler default) | WAR `web.xml` (`jruby.min.runtimes`/`jruby.max.runtimes`) |
| Kaui | DB pool | 50 | `KAUI_DB_POOL` |
| Kaui | Kill Bill timeouts | 60s / 60s | `KAUI_KILLBILL_READ_TIMEOUT`, `KAUI_KILLBILL_CONNECTION_TIMEOUT` (ms) |
| Kaui | Rails log level / format | INFO, logback (file + stdout) | `logback.xml` in the WAR, or `-Dlogback.configurationFile=...` |
| Kaui | log file location | `./logs/kaui.out`, relative to the directory Tomcat was started from | `LOGS_DIR` (env or `-DLOGS_DIR=`) |

JMX is open on port 8000 (`JVM_JMX_PORT`) and JDWP on 12345 (`JVM_JDWP_PORT`), as in production.
