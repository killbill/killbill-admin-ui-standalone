# frozen_string_literal: true

module Jdbc
  module MariaDB
    DRIVER_VERSION = '3.0.4'

    def self.driver_jar
      File.expand_path("../../lib/mariadb-java-client-#{DRIVER_VERSION}.jar", __dir__)
    end

    def self.load_driver(method = :load)
      send method, driver_jar
    end

    def self.driver_name
      'org.mariadb.jdbc.Driver'
    end

    if defined?(JRUBY_VERSION) && # enable backwards-compat behavior :
       (Java::JavaLang::Boolean.get_boolean('jdbc.driver.autoload') ||
         Java::JavaLang::Boolean.get_boolean('jdbc.mariadb.autoload') ||
         java.lang.System.getProperty('kaui.db.adapter', ENV.fetch('KAUI_DB_ADAPTER', 'mariadb')) == 'mariadb')
      warn "autoloading JDBC driver on require 'jdbc/mariadb'" if $VERBOSE
      load_driver :require
    end
  end
end
