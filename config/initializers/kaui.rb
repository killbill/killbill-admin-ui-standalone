# Configure Kaui Preferences
module Kaui
  mattr_accessor :plugins_whitelist
end

if defined?(JRUBY_VERSION)
  Kaui.demo_mode = ((java.lang.System.getProperty('kaui.demo', 'false') =~ /^true$/i) == 0)
  Kaui.plugins_whitelist = (Kaui.demo_mode ? ['analytics-plugin'] : nil)
  Kaui.root_username = java.lang.System.getProperty('kaui.root_username', 'admin')
else
  Kaui.demo_mode = false
  Kaui.plugins_whitelist = nil
  Kaui.root_username = 'admin'
end
