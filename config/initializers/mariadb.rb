# frozen_string_literal: true

module Jdbc
  module MariaDB
    DRIVER_VERSION = '2.2.0'
    VERSION = DRIVER_VERSION

    def self.driver_jar
      "mariadb-java-client-#{DRIVER_VERSION}.jar"
    end

    def self.load_driver(method = :load)
      send method, driver_jar
    end

    def self.driver_name
      'org.mariadb.jdbc.Driver'
    end

    if defined?(JRUBY_VERSION) && java.lang.System.getProperty('kaui.db.adapter', ENV.fetch('KAUI_DB_ADAPTER', nil)) == 'mariadb'
      warn "autoloading JDBC driver on require 'jdbc/mariadb'" if $VERBOSE
      load_driver :require
    end
  end
end
