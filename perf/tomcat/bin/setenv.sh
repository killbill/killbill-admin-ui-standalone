# JVM Options
CATALINA_OPTS="-server
               -showversion
               -XX:+PrintCommandLineFlags
               -XX:+HeapDumpOnOutOfMemoryError
               -XX:HeapDumpPath=${CATALINA_BASE}/logs/
               -XX:+UseCodeCacheFlushing
               -Xms${TOMCAT_JAVA_XMS:-512m}
               -Xmx${TOMCAT_JAVA_XMX:-2G}
               -Xrunjdwp:transport=dt_socket,server=${JVM_JDWP_SERVER:-y},suspend=n,address=${JVM_JDWP_PORT:-12345}
               -XX:-OmitStackTraceInFastThrow
               -XX:+UseG1GC
               -XX:+ScavengeBeforeFullGC
               -XX:SurvivorRatio=${JVM_SURVIVOR_RATIO:-10}
               -XX:+DisableExplicitGC
               "

if [ -z ${TOMCAT_DISABLE_GC_LOGGING+x} ]; then
  export CATALINA_OPTS="$CATALINA_OPTS
                       -Xlog:gc*=debug,safepoint*=debug,age*=debug:file=${CATALINA_BASE}/logs/gc.log
                       "
fi

# Java Properties
export CATALINA_OPTS="$CATALINA_OPTS
                      -Dorg.apache.tomcat.util.digester.PROPERTY_SOURCE=org.apache.tomcat.util.digester.EnvironmentPropertySource
                      -Dcom.sun.xml.bind.v2.bytecode.ClassTailor.noOptimize=true
                      -Dcom.sun.management.jmxremote=true
                      -Dcom.sun.management.jmxremote.authenticate=false
                      -Dcom.sun.management.jmxremote.port=${JVM_JMX_PORT:-8000}
                      -Dcom.sun.management.jmxremote.rmi.port=${JVM_JMX_PORT:-8000}
                      -Dcom.sun.management.jmxremote.ssl=false
                      -Djava.rmi.server.hostname=${ENV_HOST_IP:-localhost}
                      -Djava.security.egd=file:/dev/./urandom
                      -Djruby.compile.invokedynamic=false
                      -Dlog4jdbc.sqltiming.error.threshold=${JVM_JMX_PORT:-1000}"

# Allow for further customization
if [ -r "$CATALINA_BASE/bin/setenv2.sh" ]; then
  . "$CATALINA_BASE/bin/setenv2.sh"
fi

# Strip newlines (https://bz.apache.org/bugzilla/show_bug.cgi?id=63815)
export CATALINA_OPTS="$(echo $CATALINA_OPTS)"
