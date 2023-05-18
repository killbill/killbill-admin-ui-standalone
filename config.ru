# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require File.expand_path('config/environment', __dir__)
map ENV['RAILS_RELATIVE_URL_ROOT'] || '/' do
  run KauiStandalone::Application
end
