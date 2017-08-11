# https://github.com/jruby/activerecord-jdbc-adapter/issues/780
# https://github.com/rails/rails/commit/ae39b1a03d0a859be9d5342592c8936f89fcbacf
require 'active_record/connection_adapters/postgresql/schema_definitions'
class ActiveRecord::ConnectionAdapters::PostgreSQL::ColumnDefinition < ActiveRecord::ConnectionAdapters::ColumnDefinition
  attr_accessor :array
end
