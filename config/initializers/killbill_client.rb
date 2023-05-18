# frozen_string_literal: true

# KillBillClient.url ||= won't work because the client raises a ConfigurationError when url is undefined
kb_url = nil
if defined?(JRUBY_VERSION)
  kb_url = java.lang.System.getProperty('kaui.url')
  KillBillClient.disable_ssl_verification = java.lang.System.getProperty('kaui.disable_ssl_verification') == 'true' unless java.lang.System.getProperty('kaui.disable_ssl_verification').nil?
  KillBillClient.read_timeout = java.lang.System.getProperty('kaui.read_timeout')&.to_i
  KillBillClient.connection_timeout = java.lang.System.getProperty('kaui.connection_timeout')&.to_i
end

# Two sets of environment variables for legacy reasons
KillBillClient.url = (kb_url || ENV['KILLBILL_URL'] || ENV['KAUI_KILLBILL_URL'] || 'http://127.0.0.1:8080')
KillBillClient.disable_ssl_verification ||= ((ENV['KILLBILL_DISABLE_SSL_VERIFICATION'] || ENV['KAUI_KILLBILL_DISABLE_SSL_VERIFICATION'] || 'false') == 'true')
KillBillClient.read_timeout ||= (ENV['KILLBILL_READ_TIMEOUT'] || ENV['KAUI_KILLBILL_READ_TIMEOUT'] || 60_000).to_i
KillBillClient.connection_timeout ||= (ENV['KILLBILL_CONNECTION_TIMEOUT'] || ENV['KAUI_KILLBILL_CONNECTION_TIMEOUT'] || 60_000).to_i
