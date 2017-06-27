set -e

# get the version from the pom and then store it on a file on the root
VERSION=`grep -E '<version>([0-9]+\.[0-9]+\.[0-9]+)</version>' pom.xml | sed 's/[\t \n]*<version>\(.*\)<\/version>[\t \n]*/\1/'`
echo 'version: '$VERSION > version.yml

export RAILS_ENV=production

BUNDLE="bundle exec"
RAKE="$BUNDLE rake"

$RAKE assets:clobber tmp:clear

# We cannot pre-compile assets unfortunately as it breaks Tomcat deployments in sub-directories
#$RAKE assets:precompile

$BUNDLE warble

# For quick testing:
#$BUNDLE warble executable war
