# frozen_string_literal: true

Warbler::Config.new do |config|
  # Don't use gemjar, it seems it makes Gem load paths leak outside of the war
  # It also requires a custom cacheMaxSize config (https://tomcat.apache.org/tomcat-9.0-doc/config/resources.html)
  # config.features = %w(gemjar)

  # Application directories to be included in the webapp.
  config.dirs = %w[app config db lib public script vendor]

  config.gem_excludes = [%r{^(tests?|spec)/}, # Careful not to ignore things like rack-test (required by actionpack)
                         %r{^(examples?|doc-api|guides?)/}]

  config.includes = FileList['version.yml']

  config.java_classes = FileList['logback.xml']

  config.webxml.jruby.rack.logging = 'slf4j'

  # Rack::Chunked was removed in Rack 3 (Rails 7.2), so disable jruby-rack's
  # dechunking boot hook, which otherwise fails to `require 'rack/chunked'`.
  config.webxml.jruby.rack.response.dechunk = 'false'

  config.jar_name = 'killbill-admin-ui-standalone'
end
