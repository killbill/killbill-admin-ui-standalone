# frozen_string_literal: true

source 'https://rubygems.org'

gem 'jquery-rails', '~> 4.5.1'
gem 'mustache-js-rails', '~> 0.0.7'
# Staying on Rails 6.x as JRuby 9.4 is not yet supported with Warbler (https://github.com/jruby/warbler/issues/539)
gem 'rails', '~> 6.1'
gem 'sprockets-rails'

gem 'kaui', '~> 2.2.0'
# gem 'kaui', path: '../killbill-admin-ui'
# gem 'kaui', github: 'killbill/killbill-admin-ui', ref: 'master'

gem 'kanaui', '~> 2.2.0'
# gem 'kanaui', :path => '../killbill-analytics-ui'
# gem 'kanaui', github: 'killbill/killbill-analytics-ui', ref: 'master'

gem 'killbill-avatax', '~> 2.2.0'
# gem 'killbill-avatax', :path => '../killbill-avatax-ui'
# gem 'killbill-avatax', github: 'killbill/killbill-avatax-ui', ref: 'master'

gem 'killbill-kpm-ui', '~> 2.1.0'
# gem 'killbill-kpm-ui', :path => '../killbill-kpm-ui'
# gem 'killbill-kpm-ui', github: 'killbill/killbill-kpm-ui', ref: 'master'

gem 'killbill-payment-test-ui', '~> 2.1.0'
# gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
# gem 'killbill-payment-test-ui', github: 'killbill/killbill-payment-test-ui', ref: 'master'

gem 'kenui', '~> 2.1.0'
# gem 'kenui', :path => '../killbill-email-notifications-ui'
# gem 'kenui', github: 'killbill/killbill-email-notifications-ui', ref: 'master'

gem 'killbill-deposit', '~> 0.1.0'
# gem 'killbill-deposit', :path => '../killbill-deposit-ui'
# gem 'killbill-deposit', github: 'killbill/killbill-deposit-ui', ref: 'main'

gem 'killbill-client'
# gem 'killbill-client', :path => '../killbill-client-ruby'
# gem 'killbill-client', github: 'killbill/killbill-client-ruby', ref: 'master'

gem 'i18n'
gem 'tzinfo-data'

if defined?(JRUBY_VERSION)
  # JRuby jars ending up in the war
  # JRuby 9.4 not yet supported: https://github.com/jruby/warbler/issues/539
  gem 'jruby-jars', '~> 9.3.10.0'

  gem 'therubyrhino'

  gem 'nio4r', '2.5.2', platforms: :jruby

  # Unlike other repos, we cannot rely on git:// here (won't work in the war, see https://github.com/jruby/warbler/issues/537)
  gem 'activerecord-jdbc-adapter'
  # Add the drivers
  gem 'jdbc-postgres'
  gem 'jdbc-sqlite3'
  # Too old, driver is checked-in
  # gem 'jdbc-mariadb'
else
  gem 'mysql2'
  gem 'pg'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'uglifier'
end

group :development do
  gem 'listen'
  gem 'puma'
  gem 'rubocop'
  gem 'warbler', github: 'jruby/warbler', ref: 'master' if defined?(JRUBY_VERSION)
end

group :test do
  gem 'minitest'
end

# Add additional gem dependencies if needed
instance_eval File.read('Gemfile.overlay') if File.exist?('Gemfile.overlay')
