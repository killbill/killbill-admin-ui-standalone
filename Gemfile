source 'https://rubygems.org'

gem 'rails', '~> 5.1'
gem 'jquery-rails', '~> 4.3'
# See https://github.com/seyhunak/twitter-bootstrap-rails/issues/897
#gem 'twitter-bootstrap-rails', :github => 'seyhunak/twitter-bootstrap-rails', :ref => 'c236286b7d6e73affa1597f62fd51e9dbd268f1c'
gem 'twitter-bootstrap-rails'
gem 'sprockets-rails', '~> 3.2'

gem 'kaui', '~> 0.16'
#gem 'kaui', :path => '../killbill-admin-ui'
#gem 'kaui', :github => 'killbill/killbill-admin-ui', :ref => 'HEAD'

gem 'kanaui', '~> 0.6'
#gem 'kanaui', :path => '../killbill-analytics-ui'
#gem 'kanaui', :github => 'killbill/killbill-analytics-ui', :ref => 'HEAD'

gem 'killbill-avatax', '~> 0.2'
#gem 'killbill-avatax', :path => '../killbill-avatax-ui'
#gem 'killbill-avatax', :github => 'killbill/killbill-avatax-ui', :ref => 'HEAD'

gem 'killbill-kpm', '~> 0.3'
#gem 'killbill-kpm', :path => '../killbill-kpm-ui'
#gem 'killbill-kpm', :github => 'killbill/killbill-kpm-ui', :ref => 'HEAD'

#gem 'killbill-payment-test-ui', '~> 0.1'
#gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
gem 'killbill-payment-test-ui', :github => 'killbill/killbill-payment-test-ui', :ref => 'HEAD'

gem 'kenui', '~> 0.1'
#gem 'kenui', :path => '../killbill-email-notifications-ui'
#gem 'kenui', :github => 'killbill/killbill-email-notifications-ui', :ref => 'HEAD'

gem 'killbill-client', '~> 1.11'
#gem 'killbill-client', :path => '../killbill-client-ruby'
#gem 'killbill-client', :github => 'killbill/killbill-client-ruby', :ref => 'HEAD'

gem 'tzinfo-data', '~> 1.2016', '>= 1.2016.3'
gem 'i18n', '~> 0.8.0'

if defined?(JRUBY_VERSION)
  gem 'warbler', '~> 2.0.0'

  gem 'therubyrhino', '~> 2.0.4'

  # Releases for Rails 5.1 aren't available yet
  github 'jruby/activerecord-jdbc-adapter', ref: '37c67328e1d53ce4e33671b65a0f43fac777524c' do
    # Pulls activerecord-jdbc-adapter and jdbc-mysql
    gem 'activerecord-jdbcmysql-adapter'
    # Add MariaDB driver as well
    gem 'jdbc-mariadb'
    # Pulls activerecord-jdbc-adapter and jdbc-postgres
    gem 'activerecord-jdbcpostgresql-adapter'
    # Pulls activerecord-jdbc-adapter and jdbc-sqlite3
    gem 'activerecord-jdbcsqlite3-adapter'
  end
else
  gem 'therubyracer', '~> 0.12.2'

  gem 'sqlite3'
  gem 'mysql2'
  gem 'pg'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '~> 5.0'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '~> 3.2'
end

group :development do
  gem 'listen'
  gem 'puma'
end
