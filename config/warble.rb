# frozen_string_literal: true

Warbler::Config.new do |config|
  # Don't use gemjar, it seems it makes Gem load paths leak outside of the war
  # It also requires a custom cacheMaxSize config (https://tomcat.apache.org/tomcat-8.0-doc/config/resources.html)
  # config.features = %w(gemjar)

  # Application directories to be included in the webapp.
  config.dirs = %w[app config db lib public script vendor]

  config.gem_excludes = [%r{^(tests?|spec)/}, # Careful not to ignore things like rack-test (required by actionpack)
                         %r{^(examples?|doc-api|guides?)/}]

  # See https://github.com/jruby/warbler/issues/266
  config.includes = FileList['init.rb', 'version.yml']

  config.java_classes = FileList['logback.xml']

  config.webxml.jruby.rack.logging = 'slf4j'

  # Remove this when the latest version of jruby-rack is released
  # See this PR: https://github.com/killbill/killbill-admin-ui-standalone/pull/85
  config.java_libs.reject! { |f| File.basename(f) =~ /^jruby-rack.*\.jar$/ }

  config.jar_name = 'killbill-admin-ui-standalone'
end
