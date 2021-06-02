if defined?(JRUBY_VERSION)
  KillBillClient.url = java.lang.System.getProperty('kaui.url', 'http://127.0.0.1:8080')
  KillBillClient.disable_ssl_verification = java.lang.System.getProperty('kaui.disable_ssl_verification', 'false')
  KillBillClient.read_timeout = java.lang.System.getProperty('kaui.read_timeout', '60000').to_i
  KillBillClient.connection_timeout = java.lang.System.getProperty('kaui.connection_timeout', '60000').to_i
else
  # Respect also KAUI_KILLBILL_URL, which is used in the Ansible scripts
  KillBillClient.url = ENV['KILLBILL_URL'] || ENV['KAUI_KILLBILL_URL'] || 'http://127.0.0.1:8080'
  KillBillClient.read_timeout = (ENV['KILLBILL_READ_TIMEOUT'] || 60000).to_i
  KillBillClient.connection_timeout = (ENV['KILLBILL_CONNECTION_TIMEOUT'] || 60000).to_i
end
