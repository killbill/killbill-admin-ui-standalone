Warbler::Config.new do |config|
  # Don't use gemjar, it seems it makes Gem load paths leak outside of the war
  #config.features = %w(executable compiled)

  # Application directories to be included in the webapp.
  config.dirs = %w(app config db lib log public script vendor tmp)

  # We could do a bit better (e.g. exclude test js files) but we need to be careful to not ignore things like rack-test (required by actionpack)
  config.gem_excludes = [/^(test|spec)\//]

  # See https://github.com/jruby/warbler/issues/266
  config.includes = FileList["init.rb","version.yml"]

  config.java_classes = FileList["logback.xml"]

  config.webxml.jruby.rack.logging = 'slf4j'
end
