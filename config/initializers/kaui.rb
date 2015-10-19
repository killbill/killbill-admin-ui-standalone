# Configure Kaui Preferences
if defined?(JRUBY_VERSION)
  Kaui.demo_mode = ((java.lang.System.getProperty('kaui.demo', 'false') =~ /^true$/i) == 0)
else
  Kaui.demo_mode = false
end
