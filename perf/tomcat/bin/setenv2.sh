# Java Properties

export CATALINA_OPTS="$CATALINA_OPTS
                      ${KAUI_SYSTEM_PROPERTIES:-}"

if [  -z ${KAUI_SECRET_KEY_BASE+x} ]; then
  export KAUI_SECRET_KEY_BASE=$(head -c 1024 /dev/urandom | base64 | tr -cd "[:upper:][:digit:]" | head -c 129)
fi
