# frozen_string_literal: true

# Configure Kaui Preferences
module Kaui
  mattr_accessor :plugins_whitelist
end

chargeback_reason_codes = nil
credit_reason_codes = nil
invoice_item_reason_codes = nil
invoice_payment_reason_codes = nil
payment_reason_codes = nil
refund_reason_codes = nil
if defined?(JRUBY_VERSION)
  Kaui.demo_mode = java.lang.System.getProperty('kaui.demo')
  Kaui.plugins_whitelist = java.lang.System.getProperty('kaui.plugins_whitelist')
  Kaui.root_username = java.lang.System.getProperty('kaui.root_username')
  Kaui.disable_sign_up_link = java.lang.System.getProperty('kaui.disable_sign_up_link') == 'true' unless java.lang.System.getProperty('kaui.disable_sign_up_link').nil?

  chargeback_reason_codes = java.lang.System.getProperty('kaui.chargeback_reason_codes')
  credit_reason_codes = java.lang.System.getProperty('kaui.credit_reason_codes')
  invoice_item_reason_codes = java.lang.System.getProperty('kaui.invoice_item_reason_codes')
  invoice_payment_reason_codes = java.lang.System.getProperty('kaui.invoice_payment_reason_codes')
  payment_reason_codes = java.lang.System.getProperty('kaui.payment_reason_codes')
  refund_reason_codes = java.lang.System.getProperty('kaui.refund_reason_codes')

  securerandom_configured = false
  java.lang.System.getProperties.each do |k, v|
    if k =~ /kaui\.gateway\.([\w-]+).url/
      plugin_name = Regexp.last_match(1)
      plugin_url = v

      Kaui.gateways_urls[plugin_name] = plugin_url
    elsif k == 'java.security.egd'
      securerandom_configured = true
    end
  end

  # See https://github.com/killbill/killbill-admin-ui-standalone/issues/16
  warn("System property java.security.egd has not been set, this may cause some requests to hang because of a lack of entropy. You should probably set it to 'file:/dev/./urandom'") unless securerandom_configured
end

Kaui.demo_mode ||= (ENV['KAUI_DEMO_MODE'] || 'false') == 'true'
Kaui.plugins_whitelist ||= ENV.fetch('KAUI_PLUGINS_WHITELIST', nil)
Kaui.root_username ||= ENV['KAUI_ROOT_USERNAME'] || 'admin'
Kaui.disable_sign_up_link ||= (ENV['KAUI_DISABLE_SIGN_UP_LINK'] || 'true') == 'true'
Kaui.additional_headers_partial = 'layouts/additional_header'

chargeback_reason_codes ||= ENV.fetch('KAUI_CHARGEBACK_REASON_CODES', nil)
credit_reason_codes ||= ENV.fetch('KAUI_CREDIT_REASON_CODES', nil)
invoice_item_reason_codes ||= ENV.fetch('KAUI_INVOICE_ITEM_REASON_CODES', nil)
invoice_payment_reason_codes ||= ENV.fetch('KAUI_INVOICE_PAYMENT_REASON_CODES', nil)
payment_reason_codes ||= ENV.fetch('KAUI_PAYMENT_REASON_CODES', nil)
refund_reason_codes ||= ENV.fetch('KAUI_REFUND_REASON_CODES', nil)

Kaui.chargeback_reason_codes = chargeback_reason_codes.to_s.split(',') unless chargeback_reason_codes.blank?
Kaui.credit_reason_codes = credit_reason_codes.to_s.split(',') unless credit_reason_codes.blank?
Kaui.invoice_item_reason_codes = invoice_item_reason_codes.to_s.split(',') unless invoice_item_reason_codes.blank?
Kaui.invoice_payment_reason_codes = invoice_payment_reason_codes.to_s.split(',') unless invoice_payment_reason_codes.blank?
Kaui.payment_reason_codes = payment_reason_codes.to_s.split(',') unless payment_reason_codes.blank?
Kaui.refund_reason_codes = refund_reason_codes.to_s.split(',') unless refund_reason_codes.blank?
