source 'https://rubygems.org'

gem 'rails', '~> 7.0'
gem 'sprockets-rails'
gem 'jquery-rails', '~> 4.5.1'
gem 'mustache-js-rails', '~> 0.0.7'

gem 'jruby-jars', '~> 9.4.2'

#gem 'kaui', '~> 2.1'
#gem 'kaui', :path => '../killbill-admin-ui'
gem 'kaui', :github => 'killbill/killbill-admin-ui', :ref => 'master'

#gem 'kanaui', '~> 2.1'
#gem 'kanaui', :path => '../killbill-analytics-ui'
gem 'kanaui', :github => 'killbill/killbill-analytics-ui', :ref => 'master'

#gem 'killbill-avatax', '~> 2.1'
#gem 'killbill-avatax', :path => '../killbill-avatax-ui'
gem 'killbill-avatax', :github => 'killbill/killbill-avatax-ui', :ref => 'master'

#gem 'killbill-kpm-ui', '~> 2.0'
#gem 'killbill-kpm-ui', :path => '../killbill-kpm-ui'
gem 'killbill-kpm-ui', :github => 'killbill/killbill-kpm-ui', :ref => 'master'

#gem 'killbill-payment-test-ui', '~> 2.0'
#gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
gem 'killbill-payment-test-ui', :github => 'killbill/killbill-payment-test-ui', :ref => 'master'

#gem 'kenui', '~> 2.0'
#gem 'kenui', :path => '../killbill-email-notifications-ui'
gem 'kenui', :github => 'killbill/killbill-email-notifications-ui', :ref => 'master'

#gem 'killbill-deposit', '~> 0.0'
#gem 'killbill-deposit', :path => '../killbill-deposit-ui'
gem 'killbill-deposit', :github => 'killbill/killbill-deposit-ui', :ref => 'main'

gem 'killbill-client', '~> 3.3'
#gem 'killbill-client', :path => '../killbill-client-ruby'
#gem 'killbill-client', :github => 'killbill/killbill-client-ruby', :ref => 'master'

gem 'tzinfo-data'
gem 'i18n'

if defined?(JRUBY_VERSION)
  gem 'warbler'

  gem 'therubyrhino'

  gem 'nio4r', '2.5.2', :platforms => :jruby

  git 'https://github.com/jruby/activerecord-jdbc-adapter', branch: 'master' do
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
end

group :test do
  gem 'minitest'
end

# Add additional gem dependencies if needed
if File.exist?('Gemfile.overlay')
  instance_eval File.read('Gemfile.overlay')
end
