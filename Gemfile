source 'https://rubygems.org'

gem 'rails', '5.2'
gem 'jquery-rails', '~> 4.3'
# See https://github.com/seyhunak/twitter-bootstrap-rails/issues/897
#gem 'twitter-bootstrap-rails', :github => 'seyhunak/twitter-bootstrap-rails', :ref => 'c236286b7d6e73affa1597f62fd51e9dbd268f1c'
gem 'bootstrap', '~> 5.2.2'
gem 'sprockets-rails', '~> 3.2'
gem 'mustache-js-rails', '~> 0.0.7'

# Workarounds for https://github.com/jruby/warbler/issues/430
# bundler must be < 1.16 (e.g. use bundle _1.15.3_ install)
gem 'bundler', '~> 1.15.3'
# jruby-jars must be < 9.2
gem 'jruby-jars', '~> 9.1.14'

#gem 'kaui', '~> 2.1'
gem 'kaui', :path => '/Users/mark/github/killbill-admin-ui'
#gem 'kaui', :github => 'killbill/killbill-admin-ui', :ref => 'work-for-release-0.21.x'

gem 'kanaui', '~> 2.1'
#gem 'kanaui', :path => '../killbill-analytics-ui'
#gem 'kanaui', :github => 'killbill/killbill-analytics-ui', :ref => 'work-for-release-0.21.x'

gem 'killbill-avatax', '~> 2.1'
#gem 'killbill-avatax', :path => '../killbill-avatax-ui'
#gem 'killbill-avatax', :github => 'killbill/killbill-avatax-ui', :ref => 'work-for-release-0.21.x'

gem 'killbill-kpm-ui', '~> 2.0'
#gem 'killbill-kpm-ui', :path => '../killbill-kpm-ui'
#gem 'killbill-kpm-ui', :github => 'killbill/killbill-kpm-ui', :ref => 'work-for-release-0.21.x'

gem 'killbill-payment-test-ui', '~> 2.0'
#gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
#gem 'killbill-payment-test-ui', :github => 'killbill/killbill-payment-test-ui', :ref => 'work-for-release-0.21.x'

gem 'kenui', '~> 2.0'
#gem 'kenui', :path => '../killbill-email-notifications-ui'
# gem 'kenui', :github => 'killbill/killbill-email-notifications-ui', :ref => 'work-for-release-0.21.x'

gem 'killbill-deposit', '~> 0.0'
#gem 'killbill-deposit', :path => '../killbill-deposit-ui'
#gem 'killbill-deposit', :github => 'killbill/killbill-deposit-ui', :ref => 'main'

gem 'killbill-client', '~> 3.3'
#gem 'killbill-client', :path => '../killbill-client-ruby'
#gem 'killbill-client', :github => 'killbill/killbill-client-ruby', :ref => 'master'

gem 'tzinfo-data', '~> 1.2016', '>= 1.2016.3'
gem 'i18n', '~> 0.8.0'

if defined?(JRUBY_VERSION)
  gem 'warbler', '~> 2.0.0'

  gem 'therubyrhino', '~> 2.0.4'

  gem 'nio4r', '2.5.2', :platforms => :jruby

  # Pulls activerecord-jdbc-adapter and jdbc-mysql
  gem 'activerecord-jdbcmysql-adapter', '~> 51.1', :platforms => :jruby
  # We pull in a newer version of the MariaDB driver
  #gem 'jdbc-mariadb'
  # Pulls activerecord-jdbc-adapter and jdbc-postgres
  gem 'activerecord-jdbcpostgresql-adapter', '~> 51.1', :platforms => :jruby
  # Pulls activerecord-jdbc-adapter and jdbc-sqlite3
  gem 'activerecord-jdbcsqlite3-adapter', '~> 51.1', :platforms => :jruby
else
  gem 'therubyracer', '~> 0.12.2'

  gem 'sqlite3'
  gem 'mysql2', '~> 0.4.10'
  # https://github.com/rails/rails/issues/31673
  gem 'pg', '~> 0.21'
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

group :test do
  # https://github.com/seattlerb/minitest/issues/689
  gem 'minitest', '5.10.1'
end

# Add additional gem dependencies if needed
if File.exist?('Gemfile.overlay')
  instance_eval File.read('Gemfile.overlay')
end
