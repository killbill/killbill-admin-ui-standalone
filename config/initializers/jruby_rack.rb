# frozen_string_literal: true

# This is temporary until the issue is fixed and released https://github.com/jruby/jruby-rack/pull/252
module JRubyJars
  def self.jruby_rack_jar_path
    File.expand_path('../../lib/jruby-rack-custom.jar', __dir__)
  end
  require jruby_rack_jar_path if defined?(JRUBY_VERSION)
end
