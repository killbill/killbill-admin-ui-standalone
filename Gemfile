# frozen_string_literal: true

source 'https://rubygems.org'

gem 'concurrent-ruby', '1.3.6'
# csv is a "bundled gem" as of Ruby 3.4 (no longer a default gem), so it must
# be an explicit dependency for it to be available via Bundler.require.
# kaui's CSV-export controllers (accounts, invoices, payments, audit logs,
# account timelines) require 'csv' directly; without this, eager loading
# (production/WAR boot) crashes with LoadError: cannot load such file -- csv.
# Also declared in kaui.gemspec, but pinned here too since this app can't
# control kaui's release cadence.
gem 'csv'
# Lock i18n to 1.14.x for: https://github.com/ruby-i18n/i18n/issues/735
gem 'i18n', '~> 1.14.0'
gem 'jquery-rails', '~> 4.5.1'

# json 3.0 dropped the (still Rails 7.2-relied-upon) quirks_mode keyword from
# JSON.generate; on JRuby's Java ext this raises ArgumentError (js-routes'
# eager route JSON generation crashes at boot) instead of being silently
# ignored. Pin below 3.0 until Rails drops quirks_mode usage.
gem 'json', '~> 2.21'

# jruby-rack does not yet correctly implement the Rack 3 spec (see
# https://github.com/jruby/jruby-rack/pull/325, still pending). Rails 7.2/8.0
# both still support Rack 2.2, so pin it explicitly rather than risk silently
# running Rack 3 under an incompletely-supported jruby-rack. jruby-rack 2.0+
# declares a direct (non-vendored) dependency on rack ~> 2.2 and is the line
# that targets JRuby 10/JDK21, so pin it too to make sure warbler picks it up.
gem 'jruby-rack', '~> 2.0.0', platforms: :jruby
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
  gem 'bundler', '>= 2.7.2' # avoid the Bundler-version-mismatch prompt across JRuby 10.0.x (bundler 2.7.x) and 10.1.x (bundler 4.0.x)

  gem 'activerecord-jdbc-adapter', '~> 72.0', platforms: :jruby
  gem 'jdbc-mariadb'
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
