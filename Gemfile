# frozen_string_literal: true

source 'https://rubygems.org'

gem 'jquery-rails', '~> 4.5.1'
gem 'mustache-js-rails', '~> 0.0.7'
gem 'rails', '~> 7.0.1'
gem 'sprockets-rails'

gem 'jruby-jars', '~> 9.4.2'

gem 'kaui'
# gem 'kaui', path: '../killbill-admin-ui'
# gem 'kaui', github: 'killbill/killbill-admin-ui', ref: 'master'

gem 'kanaui'
# gem 'kanaui', :path => '../killbill-analytics-ui'
# gem 'kanaui', github: 'killbill/killbill-analytics-ui', ref: 'master'

gem 'killbill-avatax'
# gem 'killbill-avatax', :path => '../killbill-avatax-ui'
# gem 'killbill-avatax', github: 'killbill/killbill-avatax-ui', ref: 'master'

gem 'killbill-kpm-ui'
# gem 'killbill-kpm-ui', :path => '../killbill-kpm-ui'
# gem 'killbill-kpm-ui', github: 'killbill/killbill-kpm-ui', ref: 'master'

gem 'killbill-payment-test-ui'
# gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
# gem 'killbill-payment-test-ui', github: 'killbill/killbill-payment-test-ui', ref: 'master'

gem 'kenui'
# gem 'kenui', :path => '../killbill-email-notifications-ui'
# gem 'kenui', github: 'killbill/killbill-email-notifications-ui', ref: 'master'

gem 'killbill-deposit'
# gem 'killbill-deposit', :path => '../killbill-deposit-ui'
# gem 'killbill-deposit', github: 'killbill/killbill-deposit-ui', ref: 'main'

gem 'killbill-client'
# gem 'killbill-client', :path => '../killbill-client-ruby'
# gem 'killbill-client', github: 'killbill/killbill-client-ruby', ref: 'master'

# gem 'killbill-assets-ui', :path => '../killbill-assets-ui'
# gem 'killbill-assets-ui', github: 'killbill/killbill-assets-ui', ref: 'main'
gem 'killbill-assets-ui'

# gem 'killbill-aviate', :path => '../killbill-aviate-ui'
# gem 'killbill-aviate', github: 'killbill/killbill-aviate-ui', ref: 'main'
gem 'killbill-aviate'

gem 'i18n'
gem 'tzinfo-data'

# This fix is temporary until the next release of the gem
# See https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
gem 'concurrent-ruby', '1.3.4'

if defined?(JRUBY_VERSION)
  gem 'activerecord-jdbc-adapter', '~> 70.0', platforms: :jruby
  gem 'jdbc-mariadb'
  gem 'jdbc-mysql'
  gem 'jdbc-postgres'
  gem 'jdbc-sqlite3'

  # See https://github.com/killbill/technical-support/issues/209
  gem 'net-imap', '0.5.6'

  gem 'nio4r', '2.7.0', platforms: :jruby
  gem 'therubyrhino'

  # See https://github.com/jruby/warbler/issues/508
  gem 'warbler', github: 'jruby/warbler', branch: 'master'
else
  gem 'mysql2'
  gem 'pg'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'uglifier'
end

group :development do
  gem 'gem-release'
  gem 'listen'
  gem 'puma'
  gem 'rubocop'
end

group :test do
  gem 'minitest'
end

# Add additional gem dependencies if needed
instance_eval File.read('Gemfile.overlay') if File.exist?('Gemfile.overlay')
