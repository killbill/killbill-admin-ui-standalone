set -e

if $(ruby -e'require "java"'); then
  # Good
  echo "Detected JRuby"
else
  echo "Unable to release: make sure to use JRuby"
  exit 1
fi

VERSION=`grep -E '<version>([0-9]+\.[0-9]+\.[0-9]+)</version>' pom.xml | sed 's/[\t \n]*<version>\(.*\)<\/version>[\t \n]*/\1/'`

echo "Building artifact"
bash -x build.sh

ARTIFACT="$PWD/killbill-admin-ui-standalone.war"
echo "Pushing $ARTIFACT to Maven Central"
mvn gpg:sign-and-deploy-file \
    -DgroupId=org.kill-bill.billing.kaui \
    -DartifactId=kaui-standalone \
    -Dversion=$VERSION \
    -Dpackaging=war \
    -DrepositoryId=ossrh-releases \
    -Durl=https://oss.sonatype.org/service/local/staging/deploy/maven2/ \
    -Dfile=$ARTIFACT \
    -DpomFile=pom.xml
