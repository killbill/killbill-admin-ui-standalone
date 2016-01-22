# Configure Kaui Preferences
module Kaui
  mattr_accessor :plugins_whitelist
end

if defined?(JRUBY_VERSION)
  Kaui.demo_mode = ((java.lang.System.getProperty('kaui.demo', 'false') =~ /^true$/i) == 0)
  Kaui.plugins_whitelist = (Kaui.demo_mode ? ['analytics-plugin'] : nil)
else
  Kaui.demo_mode = false
  Kaui.plugins_whitelist = nil
end
