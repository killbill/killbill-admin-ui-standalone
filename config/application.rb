require_relative 'boot'

require 'rails/all'

require 'avatax'
require 'kpm'
require 'payment_test'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module KauiStandalone
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.after_initialize do
      Kanaui.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      Kanaui.layout = Kaui.config[:layout]

      Avatax.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      Avatax.layout = Kaui.config[:layout]

      KPM.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      KPM.layout = Kaui.config[:layout]

      PaymentTest.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      PaymentTest.layout = Kaui.config[:layout]
    end
  end
end
