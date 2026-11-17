#!/usr/bin/env bash
# GC comparison matrix for killbill/killbill-admin-ui-standalone#137  (G1 vs ZGC vs Shenandoah).
#
# Runs on YOUR machine (needs the .pem). It drives two hosts over SSH:
#   * Kaui server   : switches GC / heap via a systemd drop-in, restarts kaui, records JFR, collects gc.log
#   * Gatling box   : runs the Gatling scenarios against Kaui
#
# The Kaui password is read from the environment and sent to the Gatling box on stdin only
# (never on a command line). You start the script, so you are the one authenticating:
#
#   KAUI_PASSWORD="$(cat ~/path/to/password-file)" ./run-matrix.sh --phase smoke
#
# Phases:
#   prepare     patch /var/lib/tomcat/bin/setenv.sh on Kaui (backup first) so GC/heap/indy come from env vars
#   smoke       G1, 'mix', 120 s: validates the whole chain end to end
#   workingset  G1 only, 'mix' at -Xmx 2G/1G/768m/512m, heap samples + live histogram
#   matrix      every GC in --gc x every scenario in --scenarios, 600 s each, JFR + gc.log
#   restore     remove the drop-in, back to G1/2G/indy off, restart kaui
#   all         workingset, then matrix (default)
#
# Options: --phase P  --gc "g1 zgc shenandoah"  --scenarios "mix account_show timeline"
#          --users N (10)  --duration S (600)  --warmup S (180)  --indy true|false (false)
#          --out DIR  --yes (no confirmation)  --no-restore  --dry-run
# Finished runs leave a DONE file, so re-running the same command resumes where it stopped.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$HERE/kaui-helper.sh"

KEY="${KEY:-$HOME/Documents/killbill/kb-perf_test.pem}"
KAUI_HOST="${KAUI_HOST:-32.192.26.27}"       # SSH to the Kaui server (public IP)
KAUI_PRIV="${KAUI_PRIV:-10.0.1.223}"         # Kaui address as seen from the Gatling box
GATLING_HOST="${GATLING_HOST:-100.57.163.49}"
SSH_USER="${SSH_USER:-ubuntu}"
KAUI_USER="${KAUI_USER:-admin}"

PHASE=all
GCS="g1 zgc shenandoah"
SCENARIOS="mix account_show timeline"
USERS=10; RAMP=30; DURATION=600; WARMUP=180
WS_DURATION=300; WS_WARMUP=90; WS_XMX="2G 1G 768m 512m"
INDY=false
# Single-page scenarios use the "profile one page in isolation" settings from perf/README.md
SINGLE_LARGE_PCT="${SINGLE_LARGE_PCT:-100}"; SINGLE_THINK_MIN="${SINGLE_THINK_MIN:-0}"; SINGLE_THINK_MAX="${SINGLE_THINK_MAX:-0}"
OUT="$HERE/results"
ASSUME_YES=0; DRY=0; RESTORE=1; CONFIG_CHANGED=0
DATE="$(date +%Y%m%d)"

while [ $# -gt 0 ]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --gc) GCS="$2"; shift 2 ;;
    --scenarios) SCENARIOS="$2"; shift 2 ;;
    --users) USERS="$2"; shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --warmup) WARMUP="$2"; shift 2 ;;
    --indy) INDY="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    --no-restore) RESTORE=0; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,29p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
  esac
done

for g in $GCS; do case "$g" in g1|zgc|shenandoah) ;; *) echo "unknown gc '$g' (g1|zgc|shenandoah)" >&2; exit 2 ;; esac; done
case "$INDY" in true|false) ;; *) echo "--indy must be true or false" >&2; exit 2 ;; esac

mkdir -p "$OUT"
SSH_OPTS=(-i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15
          -o ServerAliveInterval=30 -o StrictHostKeyChecking=accept-new)

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$OUT/run.log" >&2; }
die() { log "ERROR: $*"; exit 1; }
nap() { [ "$DRY" = 1 ] || sleep "$1"; }

# --- ssh wrappers (stdin is passed through) ---------------------------------------------------
ksh() {
  if [ "$DRY" = 1 ]; then echo "  [dry] kaui: $*" >&2; [ -t 0 ] || cat >/dev/null; return 0; fi
  ssh "${SSH_OPTS[@]}" "$SSH_USER@$KAUI_HOST" "$@"
}
gsh() {
  if [ "$DRY" = 1 ]; then echo "  [dry] gatling: $(echo "$*" | cut -c1-110)" >&2; [ -t 0 ] || cat >/dev/null; return 0; fi
  ssh "${SSH_OPTS[@]}" "$SSH_USER@$GATLING_HOST" "$@"
}
kh() { # run a kaui-helper.sh subcommand on the Kaui host
  if [ "$DRY" = 1 ]; then echo "  [dry] kaui-helper: $*" >&2; return 0; fi
  ssh "${SSH_OPTS[@]}" "$SSH_USER@$KAUI_HOST" "bash -s -- $*" < "$HELPER"
}

gc_opts() {
  case "$1" in
    g1) echo "-XX:+UseG1GC" ;;
    zgc) echo "-XX:+UseZGC -XX:+ZGenerational" ;;
    shenandoah) echo "-XX:+UseShenandoahGC" ;;
    *) die "unknown gc '$1' (g1|zgc|shenandoah)" ;;
  esac
}
gc_expect() {
  case "$1" in
    g1) echo "+UseG1GC" ;;
    zgc) echo "+UseZGC +ZGenerational" ;;
    shenandoah) echo "+UseShenandoahGC" ;;
  esac
}

# --- Kaui configuration -----------------------------------------------------------------------
prepare() {
  log "Patching setenv.sh on Kaui (backup kept as setenv.sh.bak-137-*)"
  ksh 'bash -s' <<'REMOTE' || die "prepare failed"
set -e
F=/var/lib/tomcat/bin/setenv.sh
if sudo grep -q 'JVM_GC_OPTS' "$F"; then
  echo "setenv.sh already patched"
else
  sudo cp -p "$F" "$F.bak-137-$(date +%Y%m%d-%H%M%S)"
  sudo sed -i \
    -e 's|^\( *\)-XX:+UseG1GC *$|\1${JVM_GC_OPTS:--XX:+UseG1GC}|' \
    -e '/-XX:+ScavengeBeforeFullGC/d' \
    -e 's|-Djruby.compile.invokedynamic=false|-Djruby.compile.invokedynamic=${JRUBY_INDY:-false}|' "$F"
fi
sudo grep -nE 'JVM_GC_OPTS|JRUBY_INDY|ScavengeBefore|UseG1GC' "$F"
sudo grep -q 'JVM_GC_OPTS' "$F" && sudo grep -q 'JRUBY_INDY' "$F"
REMOTE
}

restart_kaui() {
  log "Restarting kaui ..."
  ksh 'sudo systemctl restart kaui' || return 1
  kh wait || { log "Kaui did not answer within 450 s"; return 1; }
}

apply_config() { # gc xmx indy
  local gc="$1" xmx="$2" indy="$3" opts flags e
  opts="$(gc_opts "$gc")"
  log "CONFIG gc=$gc ($opts) xmx=$xmx indy=$indy"
  CONFIG_CHANGED=1
  ksh 'sudo mkdir -p /etc/systemd/system/kaui.service.d && sudo tee /etc/systemd/system/kaui.service.d/137-matrix.conf >/dev/null && sudo systemctl daemon-reload' <<EOF || die "cannot write systemd drop-in"
[Service]
Environment="JVM_GC_OPTS=$opts"
Environment="TOMCAT_JAVA_XMX=$xmx"
Environment="JRUBY_INDY=$indy"
EOF
  restart_kaui || die "kaui restart failed"
  flags="$(kh flags)"
  printf '%s\n' "$flags" > "$OUT/flags-$gc-xmx$xmx-indy$indy.txt"
  if [ "$DRY" = 0 ]; then
    for e in $(gc_expect "$gc"); do
      printf '%s' "$flags" | grep -q -- "$e" || die "running JVM does not report $e (see $OUT/flags-$gc-xmx$xmx-indy$indy.txt)"
    done
  fi
  log "JVM confirmed: $(gc_expect "$gc")"
}

restore_defaults() {
  log "Restoring defaults (G1, 2G, indy off)"
  ksh 'sudo rm -f /etc/systemd/system/kaui.service.d/137-matrix.conf; sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/kaui.service.d 2>/dev/null; sudo systemctl daemon-reload'
  restart_kaui || log "WARNING: kaui did not come back after restore, check the server"
  CONFIG_CHANGED=0
}

# --- Gatling ----------------------------------------------------------------------------------
gatling_run() { # name scenario duration  -> echoes the Gatling exit code
  local name="$1" sc="$2" dur="$3" extra="" cmd rc
  if [ "$sc" != "mix" ]; then
    extra="-Dkaui.scenario=$sc -Dkaui.largeAccountPct=$SINGLE_LARGE_PCT -Dkaui.thinkMinMs=$SINGLE_THINK_MIN -Dkaui.thinkMaxMs=$SINGLE_THINK_MAX"
  fi
  # password arrives on stdin, is exported only inside this remote shell, and stdin is closed before Maven starts
  cmd="IFS= read -r KAUI_PASSWORD; export KAUI_PASSWORD; exec </dev/null; mkdir -p ~/logs; cd ~/perf/gatling || exit 99; ./mvnw -B gatling:test -Dkaui.baseUrl=http://$KAUI_PRIV:3000 -Dkaui.username=$KAUI_USER -Dkaui.users=$USERS -Dkaui.rampSeconds=$RAMP -Dkaui.durationSeconds=$dur $extra > ~/logs/$name.log 2>&1; echo \$?"
  rc="$(printf '%s\n' "${KAUI_PASSWORD:-}" | gsh "$cmd" | tail -1)"
  echo "${rc:-0}"
}

warmup() { # seconds
  log "Warm-up: mix for ${1}s (not recorded)"
  local rc; rc="$(gatling_run "warmup-$(date +%H%M%S)" mix "$1")"
  [ "$rc" = "0" ] || log "WARNING: warm-up Gatling exit code $rc (error rate >1% or failure; see ~/logs on the Gatling box)"
}

# --- one measured run -------------------------------------------------------------------------
run_scenario() { # gc scenario duration ws(0|1) label
  local gc="$1" sc="$2" dur="$3" ws="${4:-0}" label="${5:-$1}"
  local name="$label-indy$INDY-$sc-${USERS}u-$DATE" dir c0 c1 t0 t1 cpu rc sampler=""
  dir="$OUT/$name"
  if [ -f "$dir/DONE" ]; then log "skip $name (already done)"; return 0; fi
  mkdir -p "$dir"
  log "RUN $name  (ramp ${RAMP}s + ${dur}s, $USERS users)"
  kh mark > "$dir/jfr-start.txt" 2>&1
  c0="$(kh cpu)"; t0="$(date +%s)"
  if [ "$ws" = 1 ] && [ "$DRY" = 0 ]; then
    ( while :; do { date +%T; kh heap; } >> "$dir/heap-samples.txt" 2>&1; sleep 30; done ) &
    sampler=$!
  fi
  rc="$(gatling_run "$name" "$sc" "$dur")"
  c1="$(kh cpu)"; t1="$(date +%s)"
  if [ -n "$sampler" ]; then kill "$sampler" 2>/dev/null; wait "$sampler" 2>/dev/null; fi
  [ "$rc" = "0" ] || log "WARNING: Gatling exit code $rc for $name (error rate >1% or failure); data is still collected"
  if [ "$ws" = 1 ]; then
    log "Live working set: class histogram (forces one full GC) + heap_info"
    kh hist 60 > "$dir/class-histogram.txt" 2>&1
    kh heap > "$dir/heap-after-gc.txt" 2>&1
  fi
  kh dump "$name" > "$dir/jfr-dump.txt" 2>&1
  kh jfr "$name" > "$dir/$name.jfr"
  kh gclog > "$dir/gclog.tgz"
  gsh 'cd ~/perf/gatling/target/gatling && d=$(ls -dt kauisimulation-*/ | head -1) && tar -czf - "$d"' > "$dir/report.tgz"
  gsh "cat ~/logs/$name.log" > "$dir/gatling.log"
  cpu="$(awk -v a="${c0:-0}" -v b="${c1:-0}" -v t="$((t1 - t0))" 'BEGIN{ if (t > 0) printf "%.0f", (b - a) / 100 / t * 100; else print 0 }')"
  python3 -I "$HERE/summarize.py" "$dir" "$label" "$INDY" "$sc" "$USERS" "$cpu" >> "$OUT/summary.csv" \
    || log "WARNING: could not summarize $name"
  if [ "$DRY" = 0 ] && { [ ! -s "$dir/report.tgz" ] || [ ! -s "$dir/$name.jfr" ]; }; then
    log "WARNING: incomplete data for $name (report or JFR missing); NOT marked done, re-run to retry"
    return 1
  fi
  touch "$dir/DONE"
  log "DONE $name  (JVM CPU ~${cpu}% of one core; $(du -h "$dir" 2>/dev/null | tail -1 | cut -f1) on disk)"
}

all_done() { # gc
  local sc
  for sc in $SCENARIOS; do [ -f "$OUT/$1-indy$INDY-$sc-${USERS}u-$DATE/DONE" ] || return 1; done
}

# --- phases -----------------------------------------------------------------------------------
phase_smoke() {
  apply_config g1 2G false
  warmup 30
  run_scenario g1 mix 120 0 "smoke-g1"
}

phase_workingset() {
  local x
  for x in $WS_XMX; do
    if [ -f "$OUT/g1-xmx$x-indy$INDY-mix-${USERS}u-$DATE/DONE" ]; then log "skip working-set xmx=$x (done)"; continue; fi
    apply_config g1 "$x" "$INDY"
    warmup "$WS_WARMUP"
    run_scenario g1 mix "$WS_DURATION" 1 "g1-xmx$x"
  done
}

phase_matrix() {
  local gc sc
  for gc in $GCS; do
    if all_done "$gc"; then log "skip $gc (all scenarios done)"; continue; fi
    apply_config "$gc" 2G "$INDY"
    warmup "$WARMUP"
    for sc in $SCENARIOS; do run_scenario "$gc" "$sc" "$DURATION" 0 "$gc"; done
  done
}

# --- pre-flight, plan, cleanup ----------------------------------------------------------------
preflight() {
  [ -f "$KEY" ] || die "ssh key not found: $KEY"
  [ -f "$HELPER" ] || die "missing $HELPER"
  command -v python3 >/dev/null || die "python3 is required locally"
  case "$PHASE" in prepare|restore) ;; *) [ -n "${KAUI_PASSWORD:-}" ] || die "set KAUI_PASSWORD in the environment (see --help)";; esac
  log "Pre-flight: ssh to both hosts"
  ksh 'echo "kaui:    $(hostname) $(nproc) cpu, $(java -version 2>&1 | head -1)"' || die "cannot ssh to Kaui ($KAUI_HOST)"
  case "$PHASE" in prepare|restore) return ;; esac
  gsh 'echo "gatling: $(hostname) $(nproc) cpu"; test -s ~/perf/gatling/src/test/resources/data/accounts.csv && echo "feeder:  $(($(wc -l < ~/perf/gatling/src/test/resources/data/accounts.csv)-1)) accounts"' || die "Gatling box not ready (ssh or feeder missing)"
  gsh "curl -s -m 10 -o /dev/null -w 'kaui from gatling box: HTTP %{http_code}\n' http://$KAUI_PRIV:3000/users/sign_in" || die "Gatling box cannot reach Kaui"
  [ -s "$OUT/summary.csv" ] || python3 -I "$HERE/summarize.py" --header > "$OUT/summary.csv"
  ksh 'sudo grep -q JVM_GC_OPTS /var/lib/tomcat/bin/setenv.sh' || { log "setenv.sh not patched yet, running prepare"; prepare; }
}

plan() {
  local ncfg nsc total
  nsc=$(echo "$SCENARIOS" | wc -w); ncfg=$(echo "$GCS" | wc -w)
  case "$PHASE" in
    smoke) total=$((90 + 30 + 120 + RAMP + 90)) ;;
    workingset) total=$(( $(echo "$WS_XMX" | wc -w) * (90 + WS_WARMUP + WS_DURATION + RAMP + 120) )) ;;
    matrix) total=$(( ncfg * (90 + WARMUP + nsc * (RAMP + DURATION + 120)) )) ;;
    all) total=$(( $(echo "$WS_XMX" | wc -w) * (90 + WS_WARMUP + WS_DURATION + RAMP + 120) + ncfg * (90 + WARMUP + nsc * (RAMP + DURATION + 120)) )) ;;
    *) total=0 ;;
  esac
  cat >&2 <<EOF

=== PLAN ======================================================================
 phase:      $PHASE            output: $OUT
 kaui:       $SSH_USER@$KAUI_HOST   (Gatling reaches it at $KAUI_PRIV:3000)
 gatling:    $SSH_USER@$GATLING_HOST
 gcs:        $GCS     scenarios: $SCENARIOS
 load:       $USERS users, ramp ${RAMP}s, ${DURATION}s per scenario, warm-up ${WARMUP}s, indy=$INDY
 estimate:   ~$((total / 60)) minutes
 THIS WILL: patch setenv.sh (backup kept), add a systemd drop-in for kaui.service,
            RESTART kaui several times, and record JFR (profile) while it runs.
            Anyone else using the Kaui server (e.g. headius) will be disrupted.
 at the end: the drop-in is removed and kaui restarted on the original G1/2G settings
===============================================================================
EOF
  if [ "$ASSUME_YES" = 0 ] && [ "$DRY" = 0 ]; then
    printf 'Type "yes" to start: ' >&2; read -r a; [ "$a" = "yes" ] || die "aborted"
  fi
}

cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  gsh "pkill -f '[g]atling:test' || true" >/dev/null 2>&1
  if [ "$CONFIG_CHANGED" = 1 ] && [ "$RESTORE" = 1 ]; then restore_defaults; fi
  exit "$rc"
}
trap 'exit 130' INT TERM
trap cleanup EXIT

case "$PHASE" in
  prepare) preflight; prepare ;;
  restore) preflight; restore_defaults ;;
  smoke|workingset|matrix|all)
    preflight; plan
    case "$PHASE" in
      smoke) phase_smoke ;;
      workingset) phase_workingset ;;
      matrix) phase_matrix ;;
      all) phase_workingset; phase_matrix ;;
    esac
    log "Finished. Summary: $OUT/summary.csv" ;;
  *) die "unknown phase '$PHASE' (prepare|smoke|workingset|matrix|restore|all)" ;;
esac
