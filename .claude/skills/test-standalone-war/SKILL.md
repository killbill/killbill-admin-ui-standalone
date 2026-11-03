---
name: test-standalone-war
description: Pre-release smoke test of the killbill-admin-ui-standalone WAR (Kaui) on the two supported runtimes - Java 11 + JRuby 9.4 + Tomcat 8.5 (branch jruby9_old_branch) and Java 21 + JRuby 10 + Tomcat 11 (branch master). Builds the WAR in Docker, boots MariaDB + Kill Bill + Tomcat, then checks with curl that login, /accounts, /invoices and /payments work and that the app keeps serving new sessions. Use before cutting a kaui-standalone release, after bumping gems / JRuby / the kaui gem, or when asked to "test the WAR", "smoke test the release", "verify Tomcat 8 / Tomcat 11 / Java 11 / Java 21 compatibility".
---

# Test the killbill-admin-ui-standalone WAR before a release

Goal: make sure the WAR that `release.yml` builds **boots and doesn't crash** on each supported runtime. It is a simple
check, not a feature test.

The WAR is released for two runtime lines (build images mirror each branch's `release.yml`):

| Profile  | Build image                       | Runtime            | Branch               | Host ports (Kaui / Kill Bill) |
|----------|-----------------------------------|--------------------|----------------------|-------------------------------|
| `java11` | `jruby:9.4.15.0-jdk11`            | `tomcat:8.5-jdk11` | `jruby9_old_branch`  | 18091 / 18081                 |
| `java21` | `jruby:10.0.6.0-jdk21`            | `tomcat:11.0-jdk21`| `master`             | 18092 / 18082                 |

> `java21` always runs the Kaui container with `-Djruby.jit.exclude=Rails::Engine#call` (set in `profiles/java21.env`, same
> as production), which avoids a JRuby 10.0.x bug (see Known issues #1). Remove it after the JRuby upgrade (#133).

> The legacy build uses JRuby 9.4.**15**.0, not 9.4.10.0: that is what `release.yml` on `jruby9_old_branch` uses, and
> its `build.sh` refuses JRuby < 9.4.11.0. The JRuby that actually runs inside the WAR is the `jruby-jars` version pinned
> in that branch's `Gemfile`, independent of the build image. Override the build image with `JRUBY_IMAGE=...`.

## Run it

Needs only Docker (compose v2), git and `curl`. From the root of this repo:

```bash
.claude/skills/test-standalone-war/scripts/run.sh all       # both runtimes
.claude/skills/test-standalone-war/scripts/run.sh java11    # or java21
```

First run: ~5-8 min per profile (image pulls + gem downloads, cached in a Docker volume afterwards); later runs ~3-4
min. Use a long timeout (>= 10 min per profile) or run it in the background. Exit code is non-zero if any profile fails.

By default each profile builds **its branch as pushed to `origin`** (`git fetch` + `git archive`; the skill only has to
exist on the branch you run it from, e.g. `master` can test `jruby9_old_branch`) with the **released `kaui` gem**.

| You want to test...                                                  | Use                                           |
|----------------------------------------------------------------------|-----------------------------------------------|
| Both release branches as pushed                                      | `run.sh all`                                  |
| Your current checkout, uncommitted changes included (e.g. a Gemfile / JRuby bump) | `run.sh --working-tree java21` (be on the matching branch) |
| Another branch or tag of origin                                      | `run.sh --standalone-ref my-branch java21`    |
| An unreleased Kaui engine change (killbill-admin-ui checkout) on both runtimes | `run.sh --kaui-dir ../killbill-admin-ui all` |
| An already built WAR                                                 | `run.sh --war /path/app.war java11`           |

Other options: `--skip-build` (reuse the WAR from the previous run), `--keep` (leave
the stack up, print the URLs, login `admin` / `password`; stop it with `run.sh down <profile|all>`), `--clean-cache`,
`--work-dir DIR` (or `KAUI_WAR_TEST_DIR`; default `$TMPDIR/kaui-war-test`). Env: `KILLBILL_IMAGE` (default
`killbill/killbill:0.24.3`, as in this repo's CI), `DB_IMAGE`, `BOOT_TIMEOUT`, `JRUBY_IMAGE`, `TOMCAT_IMAGE`.

When reporting, state which branch/commit and which Kaui engine (`released gem` or `local checkout, version X`) were
tested; the script prints both. `scripts/smoke.sh <url>` can also be run on its own against any running Kaui.

## What it does, per profile

1. **Source**: the profile's branch from origin (or the working tree). With `--kaui-dir`, the engine is copied to
   `src/_kaui_local` and the Gemfile line `gem 'kaui'` becomes `gem 'kaui', path: '_kaui_local'` (Warbler packages it
   under `WEB-INF/_kaui_local`).
2. **Build**: `docker/Dockerfile.builder` = the JRuby image + `build-essential`/`git` (the GitHub runner has a compiler;
   some gems, e.g. `prism`, compile native extensions), then this repo's `build.sh` as in `release.yml`. Gems are cached in
   the volume `kaui-war-gems-<profile>-<image>`; it is dropped when a build fails (a half-installed gem would break every
   following build).
3. **Stack** (`docker/docker-compose.yml`, always fresh DBs): `killbill/mariadb:0.24` (ships the `killbill` + `kaui`
   schemas) + Kill Bill + Tomcat with the WAR as `ROOT.war`, configured via `-Dkaui.*` / `KAUI_DB_URL` like a real
   deployment.
4. **Checks** (`scripts/smoke.sh`), then logs are saved to `<work>/<profile>/out/` and the stack is removed.

## What the check covers (`scripts/smoke.sh`)

1. Login page renders; log in as `admin` / `password`.
2. A fresh Kill Bill has no tenant, so Kaui redirects to the tenant form: create one (needed to browse anything).
3. `/home`, `/accounts`, `/invoices`, `/payments`: HTTP 200, no Rails/Tomcat error text, expected heading.
4. The JSON endpoints behind the three lists (`/accounts|invoices|payments/pagination.json`): these call Kill Bill, so
   they prove Kaui <-> Kill Bill <-> DB work.
5. **After 25 more authenticated requests, a brand-new visitor can still log in** (see Known issues #1).

The script also greps `kaui.log` for HTTP 5xx / Ruby or Java exceptions / `SEVERE` and prints a warning even when the
checks passed. Plain `ERROR` lines are not used (the Kill Bill client logs every 4xx at ERROR).

## Reading results

Console: one `PASS`/`FAIL` line per check (with the reason), then a per-profile table. Files in
`<work>/<profile>/out/`: `results.txt`, `build.log`, `kaui.log` (Tomcat + Rails; Rails errors carry `rId='<request id>'`),
`stack.log` (all containers). Use `--keep` to poke at a live stack.

## Known issues (both reproduce with the released WAR, so they are not caused by Kaui engine changes)

1. **JRuby 10.0.x (and 10.1.0.0): a Hash forwarded through `(...)` arrives as a copy once the callee is JIT-compiled
   -> no session cookie after ~14 requests, nobody new can log in** (#131, closed; upgrade tracked in #133). Mounted
   engines are called as `Kaui::Engine.call(env)`, which `Rails::Railtie.method_missing(name, ...)` forwards to
   `Rails::Engine#call`; that method is compiled after 50 calls (~3-4 per request). The engine then gets a *copy* of the
   Rack env, so `env["action_controller.instance"]` set by the controller is invisible to the application's session
   middleware, `commit_csrf_token` is a no-op, the CSRF token is never stored in the session and no `Set-Cookie` is sent.
   Every login then fails with `Can't verify CSRF token authenticity` (401, then a 500
   `Could not find devise mapping`); existing sessions keep working until Tomcat restarts.
   Minimal Rails-free repro: a class with `method_missing(name, ...)` -> `public_send(name, ...)` to a method that checks
   `env.equal?(sent)`. Affected: JRuby 10.0.6.0, 10.0.7.0, 10.1.0.0. Not affected: 9.4.15.0, **10.1.1.0, 10.1.2.0**.
   JRuby tracks the forwarding problem as jruby/jruby#9472.
   **Workaround (always applied on `java21`):** `-Djruby.jit.exclude=Rails::Engine#call` (excluding only that
   method is enough; also in killbill/managed#175 and killbill-cloud#346). We do not care about the bug itself for now.
   Alternative without a JVM flag: define `Rails::Engine.call(env)` as `instance.call(env)` in an initializer (tested).
   The last check of `smoke.sh` ("new visitor can still log in") guards against it coming back. **After the move to
   JRuby >= 10.1.1 (#133):** delete `KAUI_EXTRA_JAVA_OPTS` from `profiles/java21.env` and confirm the run still passes;
   without the flag the check fails on JRuby 10.0.x.
2. **Cold-start race on Java 11 / JRuby 9.4 / Tomcat 8.5.** Several *concurrent first requests* right after deployment
   can leave the app answering HTTP 500 `Asset 'kaui/...svg' was not declared to be precompiled in production` (2 of 3
   fresh boots with a local-engine WAR, 2 of 4 with the released-gem WAR; once it never recovered without a restart).
   Strictly serial first requests were fine. Not checked on Java 21. The compose health probe is deliberately serial
   (long timeout, so a slow probe is never killed and overlapped by the next one). If a boot ends with 500s on the login
   page, suspect this, restart, re-run and report it.

## Other gotchas

* Behind a TLS-intercepting HTTPS proxy on localhost (some sandboxes/CI) the script gives the build container
  `--network host`, the proxy variables, the CA bundle and the Java truststore (`JAVA_TOOL_OPTIONS`): the
  `jar-dependencies` gem runs Maven (a JVM) during `bundle install`. Docker Hub anonymous pulls can answer `429`; re-run.
* Nothing is published or pushed; everything stays in the work dir and Docker (images, `kaui-war-gems-*` volumes; stacks
  are removed after each run unless `--keep`).
* If a release also changes the supported Kill Bill version, set `KILLBILL_IMAGE=killbill/killbill:<version>` too.

## Files

```
scripts/run.sh                    orchestrator (source -> build -> stack -> smoke test -> logs -> teardown)
scripts/smoke.sh                  curl-based checks, usable on its own against any Kaui URL
profiles/java11.env, java21.env   per-runtime settings (branch, images, ports, JVM workaround flags)
docker/Dockerfile.builder         JRuby build image + build tools
docker/docker-compose.yml         MariaDB + Kill Bill + Tomcat(WAR)
```
