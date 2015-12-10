Rails.application.config.after_initialize do

  # Make sure to copy over the migrations from the engines when they change, e.g. rake kaui:install:migrations
  if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite3'
    require 'pathname'
    migrations_dir = Pathname.new(File.dirname(__FILE__)).join('..').join('..').join('db').join('migrate')
    ActiveRecord::Migrator.migrate(File.expand_path(migrations_dir))
  end

end
