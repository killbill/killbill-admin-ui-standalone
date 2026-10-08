# frozen_string_literal: true

source 'https://rubygems.org'

gem 'concurrent-ruby', '1.3.6'
# Lock i18n to 1.14.x for: https://github.com/ruby-i18n/i18n/issues/735
gem 'i18n', '~> 1.14.0'
gem 'jquery-rails', '~> 4.5.1'

# json 3.0 dropped the quirks_mode keyword that ActiveSupport::JSON.encode
# still passes to JSON.generate; this raises ArgumentError instead of being
# silently ignored, crashing js-routes' eager route JSON generation at boot.
# Pin to the 2.x line until Rails drops that keyword (fixed in Rails 8.1.0).
gem 'json', '~> 2.21'

# Pin to the 1.2.x line: jruby-rack >= 1.3.0 requires Ruby >= 3.4 (JRuby 10),
# while this build runs on JRuby 9.4 (Ruby 3.1).
gem 'jruby-rack', '~> 1.2.0', platforms: :jruby
gem 'rack', '~> 2.2.0'

gem 'kanaui'
# gem 'kanaui', :path => '../killbill-analytics-ui'
# gem 'kanaui', github: 'killbill/killbill-analytics-ui', ref: 'master'

gem 'kaui'
# gem 'kaui', path: '../killbill-admin-ui'
# gem 'kaui', github: 'killbill/killbill-admin-ui', ref: 'master'

gem 'kenui'
# gem 'kenui', :path => '../killbill-email-notifications-ui'
# gem 'kenui', github: 'killbill/killbill-email-notifications-ui', ref: 'master'

# gem 'killbill-assets-ui', :path => '../killbill-assets-ui'
# gem 'killbill-assets-ui', github: 'killbill/killbill-assets-ui', ref: 'main'
gem 'killbill-assets-ui'

# gem 'killbill-aviate', :path => '../killbill-aviate-ui'
# gem 'killbill-aviate', github: 'killbill/killbill-aviate-ui', ref: 'main'
gem 'killbill-aviate'

gem 'killbill-avatax'
# gem 'killbill-avatax', :path => '../killbill-avatax-ui'
# gem 'killbill-avatax', github: 'killbill/killbill-avatax-ui', ref: 'master'

gem 'killbill-client'
# gem 'killbill-client', :path => '../killbill-client-ruby'
# gem 'killbill-client', github: 'killbill/killbill-client-ruby', ref: 'master'

gem 'killbill-deposit'
# gem 'killbill-deposit', :path => '../killbill-deposit-ui'
# gem 'killbill-deposit', github: 'killbill/killbill-deposit-ui', ref: 'main'

gem 'killbill-kpm-ui'
# gem 'killbill-kpm-ui', :path => '../killbill-kpm-ui'
# gem 'killbill-kpm-ui', github: 'killbill/killbill-kpm-ui', ref: 'master'

gem 'killbill-payment-test-ui'
# gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
# gem 'killbill-payment-test-ui', github: 'killbill/killbill-payment-test-ui', ref: 'master'

gem 'mustache-js-rails', '~> 0.0.7'
gem 'rails', '~> 7.2.0'
gem 'sprockets-rails'
gem 'tzinfo-data'

if defined?(JRUBY_VERSION)
  gem 'bundler', '~> 2.6.3' # match JRuby 9.4 system version, in lieu of using BUNDLE_VERSION=system

  gem 'activerecord-jdbc-adapter', '~> 72.0', platforms: :jruby
  gem 'jdbc-mariadb'
  gem 'jdbc-mysql'
  gem 'jdbc-postgres'
  gem 'jdbc-sqlite3'
  gem 'jruby-jars', '9.4.15.0'

  # See https://github.com/killbill/technical-support/issues/209
  gem 'net-imap', '0.5.6'

  gem 'nio4r', '2.7.0', platforms: :jruby
else
  gem 'mysql2'
  gem 'pg'
end

group :development do
  gem 'gem-release'
  gem 'listen'
  gem 'puma'
  gem 'rubocop'
  gem 'warbler', '~> 2.1.1', platforms: :jruby
end

group :test do
  gem 'minitest', '~> 5.0'
end

# Add additional gem dependencies if needed
instance_eval File.read('Gemfile.overlay') if File.exist?('Gemfile.overlay')
