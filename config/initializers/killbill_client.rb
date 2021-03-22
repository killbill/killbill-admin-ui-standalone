if defined?(JRUBY_VERSION)
  KillBillClient.url = java.lang.System.getProperty('kaui.url', 'http://127.0.0.1:8080')
  KillBillClient.disable_ssl_verification = java.lang.System.getProperty('kaui.disable_ssl_verification', 'false')
else
  # Respect also KAUI_KILLBILL_URL, which is used in the Ansible scripts
  KillBillClient.url = ENV['KILLBILL_URL'] || ENV['KAUI_KILLBILL_URL'] || 'http://127.0.0.1:8080'
end
