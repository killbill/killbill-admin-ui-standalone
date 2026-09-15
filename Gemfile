# frozen_string_literal: true

source 'https://rubygems.org'

gem 'concurrent-ruby', '1.3.6'
# csv is a bundled (non-default) gem as of Ruby 3.4; kaui's CSV-export controllers need it explicitly.
gem 'csv'
# Lock i18n to 1.14.x for: https://github.com/ruby-i18n/i18n/issues/735
gem 'i18n', '~> 1.14.0'
gem 'jquery-rails', '~> 4.5.1'

# json 3.0 dropped quirks_mode, which ActiveSupport::JSON still needs until Rails 8.1.
gem 'json', '~> 2.21'

# jruby-rack doesn't fully support Rack 3 yet (jruby/jruby-rack#325); pin Rack 2.2 + jruby-rack 2.0.
gem 'jruby-rack', '~> 2.0.0', platforms: :jruby
gem 'rack', '~> 2.2.0'

gem 'kanaui'
# gem 'kanaui', :path => '../killbill-analytics-ui'
# gem 'kanaui', github: 'killbill/killbill-analytics-ui', ref: 'master'

# gem 'kaui'
# gem 'kaui', path: '../killbill-admin-ui'
gem 'kaui', github: 'killbill/killbill-admin-ui', ref: 'jruby10-upgrade'

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

# Pin below irb 1.17/rdoc 8 to avoid pulling in prism/rbs transitives (console-only, not needed at runtime).
gem 'irb', '< 1.17.0'
gem 'rdoc', '< 8'

if defined?(JRUBY_VERSION)
  gem 'bundler', '>= 2.7.2' # avoid the Bundler-version-mismatch prompt across JRuby 10.0.x (bundler 2.7.x) and 10.1.x (bundler 4.0.x)

  gem 'activerecord-jdbc-adapter', '~> 72.0', platforms: :jruby
  # MySQL Connector/J (not jdbc-mariadb, abandoned upstream since 2019 at 2.4.2
  # with no caching_sha2_password support - see config/database.yml).
  gem 'jdbc-mysql'
  gem 'jdbc-postgres'
  gem 'jdbc-sqlite3'
  gem 'jruby-jars', '10.0.6.0'

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
  gem 'warbler', '~> 2.1.2', platforms: :jruby
end

group :test do
  gem 'minitest', '~> 5.0'
end

# Add additional gem dependencies if needed
instance_eval File.read('Gemfile.overlay') if File.exist?('Gemfile.overlay')
