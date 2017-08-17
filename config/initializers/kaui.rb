# Configure Kaui Preferences
module Kaui
  mattr_accessor :plugins_whitelist
end

if defined?(JRUBY_VERSION)
  Kaui.demo_mode = ((java.lang.System.getProperty('kaui.demo', 'false') =~ /^true$/i) == 0)
  Kaui.plugins_whitelist = (Kaui.demo_mode ? ['analytics-plugin'] : nil)
  Kaui.root_username = java.lang.System.getProperty('kaui.root_username', 'admin')

  chargeback_reason_codes = java.lang.System.getProperty('kaui.chargeback_reason_codes').to_s.split(',')
  Kaui.chargeback_reason_codes = chargeback_reason_codes unless chargeback_reason_codes.empty?
  credit_reason_codes = java.lang.System.getProperty('kaui.credit_reason_codes').to_s.split(',')
  Kaui.credit_reason_codes = credit_reason_codes unless credit_reason_codes.empty?
  invoice_item_reason_codes = java.lang.System.getProperty('kaui.invoice_item_reason_codes').to_s.split(',')
  Kaui.invoice_item_reason_codes = invoice_item_reason_codes unless invoice_item_reason_codes.empty?
  invoice_payment_reason_codes = java.lang.System.getProperty('kaui.invoice_payment_reason_codes').to_s.split(',')
  Kaui.invoice_payment_reason_codes = invoice_payment_reason_codes unless invoice_payment_reason_codes.empty?
  payment_reason_codes = java.lang.System.getProperty('kaui.payment_reason_codes').to_s.split(',')
  Kaui.payment_reason_codes = payment_reason_codes unless payment_reason_codes.empty?
  refund_reason_codes = java.lang.System.getProperty('kaui.refund_reason_codes').to_s.split(',')
  Kaui.refund_reason_codes = refund_reason_codes unless refund_reason_codes.empty?

  java.lang.System.getProperties.each do |k, v|
    if k =~ /kaui\.gateway\.([\w-]+).url/
      plugin_name = $1
      plugin_url = v

      Kaui.gateways_urls[plugin_name] = plugin_url
    end
  end
else
  Kaui.demo_mode = false
  Kaui.plugins_whitelist = nil
  Kaui.root_username = 'admin'
end
