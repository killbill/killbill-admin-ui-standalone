set -e

export RAILS_ENV=production

BUNDLE="bundle exec"
RAKE="$BUNDLE rake"

$RAKE assets:clobber tmp:clear

# We cannot pre-compile assets unfortunately as it breaks Tomcat deployments in sub-directories
#$RAKE assets:precompile

$BUNDLE warble

# For quick testing:
#$BUNDLE warble executable war
