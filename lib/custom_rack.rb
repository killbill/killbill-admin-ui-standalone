# frozen_string_literal: true

# This is temporary until the issue is fixed and released https://github.com/jruby/jruby-rack/pull/252
module Rack
  module Utils
    def self.bytesize(string)
      string.bytesize
    end
  end
end
