#!/usr/bin/env bash
set -e

if $(ruby -e'require "java"'); then
  # Good
  echo 'Detected JRuby'
else
  echo 'Unable to build: make sure to use JRuby'
  exit 1
fi

export RAILS_ENV=production

# 2.3.25 shipped with JRuby won't work (see https://github.com/jruby/warbler/issues/536)
gem install bundler --version=2.4.14

BUNDLE="bundle _2.4.14_"
RAILS="./bin/rails"

$BUNDLE install
$RAILS assets:clobber log:clear tmp:clear

# We cannot pre-compile assets unfortunately as it breaks Tomcat deployments in sub-directories
# $RAILS assets:precompile

$BUNDLE exec warble

# For quick testing:
#$BUNDLE warble executable war

if [[ ! -f killbill-admin-ui-standalone.war ]]; then
    printf 'war was not created!\n'
    exit 99
fi
