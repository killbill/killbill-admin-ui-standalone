# frozen_string_literal: true

class HealthCheckController < ActionController::Base
  def health
    response = { version: KauiStandalone::VERSION, status: 'UP' }
    render json: response, status: 200
  end
end
