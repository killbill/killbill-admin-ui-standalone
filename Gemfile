source 'https://rubygems.org'

gem 'i18n', '~>0.7.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '~> 5.0'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'rails', '~> 4.2.1'
gem 'jquery-rails', '~> 3.0.4'
gem 'd3_rails', '~> 3.2.8'
#gem 'twitter-bootstrap-rails', '~> 3.2.0'
# Version 3.2.1
gem 'twitter-bootstrap-rails', :github => 'seyhunak/twitter-bootstrap-rails', :ref => 'dafba608bf07df6826519adcc4f0c9510e8d93b4'
gem "js-routes", "~> 1.0.0"

#gem 'kaui', '0.11.0'
#gem 'kaui', :path => '../killbill-admin-ui'
gem 'kaui', :github => 'killbill/killbill-admin-ui', :ref => 'HEAD'

#gem 'kanaui', '0.3.0'
#gem 'kanaui', :path => '../killbill-analytics-ui'
gem 'kanaui', :github => 'killbill/killbill-analytics-ui', :ref => 'HEAD'

#gem 'killbill-avatax', '0.0.1'
#gem 'killbill-avatax', :path => '../killbill-avatax-ui'
gem 'killbill-avatax', :github => 'killbill/killbill-avatax-ui', :ref => 'HEAD'

#gem 'killbill-client', :path => '../killbill-client-ruby'
gem 'killbill-client', :github => 'killbill/killbill-client-ruby', :ref => 'HEAD'

if defined?(JRUBY_VERSION)
  gem 'warbler', '~> 1.4.9'

  gem 'therubyrhino', '~> 2.0.4'

  gem 'activerecord-jdbc-adapter', '~> 1.3.9'
  gem 'activerecord-jdbcmysql-adapter', '~> 1.3.9'
  gem 'activerecord-jdbcsqlite3-adapter', '~> 1.3.9'
  gem 'jdbc-mysql', '~> 5.1.25'
else
  gem 'therubyracer', '~> 0.12.2'

  gem 'sqlite3'
  gem 'mysql2', '0.3.17'
end


# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
