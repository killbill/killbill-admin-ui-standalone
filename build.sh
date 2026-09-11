#!/usr/bin/env bash
set -e

ruby_version="$(ruby -v 2>/dev/null || echo 'Ruby not found')"
if ruby -e 'exit RUBY_ENGINE == "jruby" && Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new("10.0.0.0")' 2>/dev/null; then
  # Good
  echo "Detected JRuby: ${ruby_version}"
else
  echo "Unable to build: make sure to use JRuby >= 10.0.0.0 (found ${ruby_version})"
  exit 1
fi

# Get the version from the pom and then store it on a file on the root
VERSION=`grep -E '<version>([0-9]+\.[0-9]+\.[0-9]+)</version>' pom.xml | sed 's/[\t \n]*<version>\(.*\)<\/version>[\t \n]*/\1/'`
echo 'version: '$VERSION > version.yml

export RAILS_ENV=production
export SECRET_KEY_BASE=$(head -c 1024 /dev/urandom | base64 | tr -cd "[:upper:][:digit:]" | head -c 129)
chmod 600 config/keys/dummy_production.key

bundle install

BUNDLE="bundle exec"
RAILS="./bin/rails"

$RAILS assets:clobber log:clear tmp:clear

# We cannot pre-compile assets unfortunately as it breaks Tomcat deployments in sub-directories
# $RAILS assets:precompile

$BUNDLE warble

# For quick testing:
#$BUNDLE warble executable war

if [[ ! -f killbill-admin-ui-standalone.war ]]; then
    printf 'war was not created!\n'
    exit 99
fi
