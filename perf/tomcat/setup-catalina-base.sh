#!/usr/bin/env bash
#
# Create a Tomcat CATALINA_BASE that mirrors the production Kaui/Kill Bill images built from
# killbill-cloud@java2x (Tomcat 11 + JDK 21), without Docker or Ansible.
#
# conf/ and bin/ in this directory were rendered from killbill-cloud@java2x (6eab879):
#   ansible/templates/tomcat/conf/{server.xml,context.xml,web.xml,setenv.sh}.j2
#   ansible/templates/kaui/conf/setenv2.sh.j2
# using the defaults from ansible/group_vars/all.yml. Every value can still be overridden at
# runtime with the same environment variables as production (TOMCAT_MAX_THREADS, TOMCAT_JAVA_XMX, ...).
#
# Usage:
#   setup-catalina-base.sh -h <CATALINA_HOME> -b <CATALINA_BASE> [-k kaui.war[:context]] [-K killbill.war[:context]]
#
# Topologies:
#   Separate Tomcats (Kaui only):   -k kaui.war                      (Kaui at /)
#   Shared Tomcat (Kaui + KB):      -K killbill.war -k kaui.war:kaui (KB at /, Kaui at /kaui)
#
set -euo pipefail

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

HERE="$(cd "$(dirname "$0")" && pwd)"
CATALINA_HOME=""
CATALINA_BASE=""
KAUI_WAR=""
KB_WAR=""

while getopts "h:b:k:K:" opt; do
  case $opt in
    h) CATALINA_HOME="$OPTARG" ;;
    b) CATALINA_BASE="$OPTARG" ;;
    k) KAUI_WAR="$OPTARG" ;;
    K) KB_WAR="$OPTARG" ;;
    *) usage ;;
  esac
done

[[ -n "$CATALINA_HOME" && -n "$CATALINA_BASE" ]] || usage
[[ -n "$KAUI_WAR" || -n "$KB_WAR" ]] || usage
[[ -x "$CATALINA_HOME/bin/catalina.sh" ]] || { echo "No Tomcat found in $CATALINA_HOME" >&2; exit 1; }

mkdir -p "$CATALINA_BASE"/{bin,conf,logs,temp,webapps,work}

# Stock Tomcat files production doesn't template (catalina.properties, logging.properties, ...)
cp -n "$CATALINA_HOME"/conf/* "$CATALINA_BASE/conf/" 2>/dev/null || true
# Production templates
cp "$HERE"/conf/{server.xml,context.xml,web.xml} "$CATALINA_BASE/conf/"
cp "$HERE"/bin/setenv.sh "$CATALINA_BASE/bin/"
if [[ -n "$KAUI_WAR" ]]; then
  cp "$HERE"/bin/setenv2.sh "$CATALINA_BASE/bin/"
fi

deploy() {
  local spec="$1" war context
  war="${spec%%:*}"
  context="ROOT"
  [[ "$spec" == *:* ]] && context="${spec#*:}"
  [[ -f "$war" ]] || { echo "WAR not found: $war" >&2; exit 1; }
  rm -rf "$CATALINA_BASE/webapps/$context" "$CATALINA_BASE/webapps/$context.war"
  cp "$war" "$CATALINA_BASE/webapps/$context.war"
  echo "Deployed $(basename "$war") as /${context/ROOT/}"
}

[[ -n "$KB_WAR" ]] && deploy "$KB_WAR"
[[ -n "$KAUI_WAR" ]] && deploy "$KAUI_WAR"

cat <<EOF

CATALINA_BASE ready: $CATALINA_BASE

Start (foreground):
  CATALINA_HOME=$CATALINA_HOME CATALINA_BASE=$CATALINA_BASE \\
  TOMCAT_PORT=8080 \\
  KAUI_KILLBILL_URL=http://127.0.0.1:8080 KAUI_DB_URL='jdbc:mysql://127.0.0.1:3306/kaui?...' \\
  KAUI_DB_USERNAME=root KAUI_DB_PASSWORD=... \\
  $CATALINA_HOME/bin/catalina.sh run

See perf/README.md for the full list of variables.
EOF
