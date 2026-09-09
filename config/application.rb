# frozen_string_literal: true

require_relative 'boot'

# We need to require it here because the function will be called in config.before_configuration
# The original function requires permission [100600 100400] which did not work with the Windows system
# See this PR: https://github.com/killbill/killbill-admin-ui-standalone/pull/72
require_relative 'initializers/symmetric_file_permission_override'
require_relative '../lib/kaui_standalone/version'
require 'rails/all'
require 'avatax'
require 'kanaui'
require 'kenui'
require 'deposit'
require 'kpm'
require 'payment_test'
require 'aviate'

ENV['KAUI_ADDITIONAL_ENGINES'].split(',').each { |e| require e } if ENV['KAUI_ADDITIONAL_ENGINES'].present?

# Work around a JRuby 10 bug (jruby/jruby#9651): assigning to an outer local
# variable named `it` inside a block silently creates a block-local shadow
# instead of updating the outer one, so op-assignments raise NoMethodError.
# sorbet-runtime 0.6.x's signature-validation code uses `it` as a loop counter
# (T::Private::Methods::Signature#each_args_value_type), so any call to a
# sig'd method (e.g. js-routes' sig-decorated methods) crashes at load time.
# Disabling runtime checks avoids building the crashing validation wrapper.
# Alternative fix (no code change): set SORBET_RUNTIME_DEFAULT_CHECKED_LEVEL=
# never as a real process env var (sorbet-runtime reads this at require time)
# - not used here since this code-level fix applies uniformly across every
# entry point (build.sh, CI, Tomcat boot) without relying on every deployment
# path remembering to set it. See killbill-admin-ui's
# test/dummy/config/application.rb for the same workaround.
if defined?(JRUBY_VERSION)
  require 'sorbet-runtime'
  T::Configuration.default_checked_level = :never
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module KauiStandalone
  WITH_LOGBACK = if defined?(JRUBY_VERSION) && begin
    org.slf4j.MDC
  rescue StandardError
    false
  end
                   true
                 else
                   false
                 end

  class Application < Rails::Application
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

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

      Kenui.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      Kenui.layout = Kaui.config[:layout]

      Deposit.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      Deposit.layout = Kaui.config[:layout]

      Aviate.current_tenant_user = lambda do |session, user|
        Kaui.current_tenant_user_options(user, session)
      end
      Aviate.layout = Kaui.config[:layout]
    end
  end
end
