# frozen_string_literal: true

module Warbler
  class Jar
    def add_init_file(config)
      return unless config.init_contents

      contents = +''
      config.init_contents.each do |file|
        contents << if file.respond_to?(:read)
                      file.read
                    elsif File.extname(file) == '.erb'
                      expand_erb(file, config).read
                    else
                      File.read(file)
                    end
      end

      @files[config.init_filename] = StringIO.new(contents)
      return unless @files[config.init_filename]

      contents = @files[config.init_filename].read
      add_before = "require 'bundler/shared_helpers'"
      line_to_add = "Gem.paths = ENV\n"
      @files[config.init_filename] = StringIO.new(contents.gsub(add_before, "#{line_to_add}\\0"))
    end
  end
end
