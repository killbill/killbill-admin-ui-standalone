#!/usr/bin/env bash
# Runs ON the Kaui server (piped over ssh by run-matrix.sh: ssh host 'bash -s -- <cmd> [args]' < kaui-helper.sh).
# Read-only except: mark/dump (JFR recording), jfr/gclog (read files), hist (forces one full GC).
set -u
PID=$(systemctl show -p MainPID --value kaui)
LOGS=/var/lib/tomcat/logs
MARK=/tmp/marker-137
J() { sudo -n -u tomcat jcmd "$PID" "$@"; }

case "${1:-}" in
  pid)   echo "$PID" ;;
  flags) J VM.flags ;;
  # Wait (max 450 s) until Kaui answers its sign-in page
  wait)
    for _ in $(seq 1 90); do
      c=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:3000/users/sign_in)
      [ "$c" = "200" ] && exit 0
      sleep 5
    done
    exit 1 ;;
  # JVM CPU time in clock ticks (utime+stime), divide by CLK_TCK (100) for seconds
  cpu)   awk '{print $14+$15}' "/proc/$PID/stat" ;;
  # Start of a measured run: marker for gc.log files, rotate gc.log, (re)start the JFR recording
  mark)
    # Rotate FIRST, then touch the marker: the rotated-out file (warm-up/startup) is then older than the
    # marker and is excluded by 'gclog'; only the fresh gc.log of the measured run is collected.
    J VM.log rotate >/dev/null 2>&1
    rm -f "$MARK"; touch "$MARK"
    J JFR.stop name=perf >/dev/null 2>&1
    J JFR.start name=perf settings=profile | tail -1 ;;
  # End of a measured run: dump the recording to the Tomcat logs dir, then stop it
  dump)
    J JFR.dump name=perf filename="$LOGS/$2.jfr" | tail -1
    J JFR.stop name=perf | tail -1 ;;
  jfr)   sudo -n cat "$LOGS/$2.jfr" ;;
  # gc.log files written since mark, as a tar.gz on stdout
  gclog) sudo -n sh -c "cd $LOGS && tar -czf - \$(find . -maxdepth 1 -name 'gc.log*' -newer $MARK)" ;;
  heap)  J GC.heap_info ;;
  # Live-object histogram. NOTE: this forces a full GC (use after the load run, never during it)
  hist)  J GC.class_histogram | head -"${2:-60}" ;;
  *) echo "usage: kaui-helper.sh pid|flags|wait|cpu|mark|dump NAME|jfr NAME|gclog|heap|hist [N]" >&2; exit 2 ;;
esac
