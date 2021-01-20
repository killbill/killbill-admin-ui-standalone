#!/usr/bin/env sh
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

BUNDLE="bundle _1.15.3_ exec"
RAILS="./bin/rails"

$RAILS assets:clobber log:clear tmp:clear

# We cannot pre-compile assets unfortunately as it breaks Tomcat deployments in sub-directories
# $RAILS assets:precompile

$BUNDLE warble

# For quick testing:
#$BUNDLE warble executable war
