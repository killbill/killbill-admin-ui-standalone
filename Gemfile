source 'https://rubygems.org'

gem 'rails', '~> 6.1.7'
gem 'js-routes'

# See https://github.com/seyhunak/twitter-bootstrap-rails/issues/897
# gem 'twitter-bootstrap-rails', :github => 'seyhunak/twitter-bootstrap-rails', :ref => 'c236286b7d6e73affa1597f62fd51e9dbd268f1c'

gem 'jquery-rails'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'sassc-rails', '>= 2.1.0'
gem 'sprockets'
gem 'sprockets-rails'
gem 'mustache-js-rails'
gem 'popper_js', '~> 2.11.5'
gem 'bootstrap-datepicker-rails'
gem 'font-awesome-sass'

# Workarounds for https://github.com/jruby/warbler/issues/430
# bundler must be < 1.16 (e.g. use bundle _1.15.3_ install)

gem 'bundler'

# jruby-jars must be < 9.2
gem 'jruby-jars'

# gem 'kaui', '~> 2.1'
gem 'kaui', :path => '../killbill-admin-ui'
# gem 'kaui', :github => 'killbill/killbill-admin-ui', :ref => 'work-for-release-0.21.x'

# gem 'kanaui', '2.1'
# gem 'kanaui', :path => '../killbill-analytics-ui'
gem 'kanaui', :github => 'kpbacode/killbill-analytics-ui', :ref => 'master'

# gem 'killbill-avatax', '~> 2.1'
# gem 'killbill-avatax', :path => '../killbill-avatax-ui'
gem 'killbill-avatax', :github => 'kpbacode/killbill-avatax-ui', :ref => 'master'

# gem 'killbill-kpm-ui', '~> 2.0'
# gem 'killbill-kpm-ui', :path => '../killbill-kpm-ui'
gem 'killbill-kpm-ui', :github => 'kpbacode/killbill-kpm-ui', :ref => 'master'

#gem 'killbill-payment-test-ui', '~> 2.0'
# gem 'killbill-payment-test-ui', :path => '../killbill-payment-test-ui'
gem 'killbill-payment-test-ui', :github => 'kpbacode/killbill-payment-test-ui', :ref => 'master'

# gem 'kenui', '~> 2.0'
gem 'kenui', :path => '../killbill-email-notifications-ui'
# gem 'kenui', :github => 'killbill/killbill-email-notifications-ui', :ref => 'work-for-release-0.21.x'

#gem 'killbill-deposit', '~> 0.0'
# gem 'killbill-deposit', :path => '../killbill-deposit-ui'
gem 'killbill-deposit', :github => 'kpbacode/killbill-deposit-ui', :ref => 'main'

gem 'killbill-client', '~> 3.3'
# gem 'killbill-client', :path => '../killbill-client-ruby'
# gem 'killbill-client', :github => 'killbill/killbill-client-ruby', :ref => 'master'

gem 'tzinfo-data', '~> 1.2016', '>= 1.2016.3'
gem 'i18n'

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
  gem 'mini_racer'
  gem 'sqlite3'
  gem 'mysql2'
  # https://github.com/rails/rails/issues/31673
  gem 'pg'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier'
end

group :development do
  gem 'listen'
  gem 'puma'
end

group :test do
  # https://github.com/seattlerb/minitest/issues/689
  gem 'minitest'
end

# Add additional gem dependencies if needed
if File.exist?('Gemfile.overlay')
  instance_eval File.read('Gemfile.overlay')
end

