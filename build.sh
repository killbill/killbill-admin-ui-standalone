set -e

export RAILS_ENV=production

BUNDLE="bundle exec"
RAKE="$BUNDLE rake"

$RAKE assets:clean tmp:clear
$RAKE assets:precompile
$BUNDLE warble

# For quick testing:
# $BUNDLE warble executable war
