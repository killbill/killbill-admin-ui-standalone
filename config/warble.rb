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

  config.jar_name = 'killbill-admin-ui-standalone'
end

module FixInit
  def add_init_file(config)
    super
    return unless @files[config.init_filename]

    contents = @files[config.init_filename].read
    add_before = "require 'bundler/shared_helpers'"
    line_to_add = "Gem.paths = ENV\n"
    @files[config.init_filename] = StringIO.new(contents.gsub(add_before, "#{line_to_add}\\0"))
  end
end

module Warbler
  class Jar
    prepend FixInit
  end
end
