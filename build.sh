#!/usr/bin/env bash
set -e

if $(ruby -e'require "java"'); then
  # Good
  echo 'Detected JRuby'
else
  echo 'Unable to build: make sure to use JRuby'
  exit 1
fi

# Get the version from the pom and then store it on a file on the root
VERSION=`grep -E '<version>([0-9]+\.[0-9]+\.[0-9]+)</version>' pom.xml | sed 's/[\t \n]*<version>\(.*\)<\/version>[\t \n]*/\1/'`
echo 'version: '$VERSION > version.yml

export RAILS_ENV=production
export SECRET_KEY_BASE=$(head -c 1024 /dev/urandom | base64 | tr -cd "[:upper:][:digit:]" | head -c 129)
chmod 600 config/keys/dummy_production.key

# 2.3.25 shipped with JRuby won't work
gem update bundler
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
