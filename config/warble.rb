Warbler::Config.new do |config|
  # Don't use gemjar, it seems it makes Gem load paths leak outside of the war
  #config.features = %w(executable compiled)

  # Application directories to be included in the webapp.
  config.dirs = %w(app config db lib log public script vendor tmp)
end
