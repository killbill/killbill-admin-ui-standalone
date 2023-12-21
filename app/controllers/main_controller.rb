# frozen_string_literal: true

class MainController < ApplicationController
  def available_engines
    render json: find_available_plugins
  end

  private

  def find_available_plugins
    plugins = []

    nodes_info = KillBillClient::Model::NodesInfo.nodes_info(options_for_klient) || []
    plugins_info = nodes_info.empty? ? [] : (nodes_info.first.plugins_info || [])

    #
    # Convention for the artifactId which is used for the filesystem install path and later reflected in the `plugin_name` is
    # <plugin_key>-plugin (e.g plugin_key='avatax' => plugin_name = 'avatax-plugin')
    #
    # Note that convention is broken for 'email-notifications' : plugin_key = 'email-notifications' => artifact_id = 'killbill-email-notifications-plugin'
    #
    plugins_info.each do |plugin_info|
      next unless plugin_info.state == 'RUNNING'
      next unless Kaui.plugins_whitelist.nil? || Kaui.plugins_whitelist.include?(plugin_info.plugin_name)

      if plugin_info.plugin_name == 'analytics-plugin'
        plugins << {
          path: kanaui_engine_path,
          name: 'Analytics'
        }
      elsif plugin_info.plugin_name == 'avatax-plugin'
        plugins << {
          path: avatax_engine_path,
          name: 'Avatax'
        }
      elsif plugin_info.plugin_name == 'org.kill-bill.billing.killbill-platform-osgi-bundles-kpm' && current_user.root?
        plugins << {
          path: kpm_engine_path,
          name: 'KPM'
        }
      elsif plugin_info.plugin_name == 'payment-test-plugin' && current_user.root?
        plugins << {
          path: payment_test_engine_path,
          name: 'Payment Test'
        }
      elsif plugin_info.plugin_name == 'email-notifications-plugin' && current_user.root?
        plugins << {
          path: kenui_engine_path,
          name: 'E-notifications'
        }
      elsif plugin_info.plugin_name == 'deposit-plugin'
        plugins << {
          path: deposit_engine_path,
          name: 'Deposit'
        }
      end
    end

    plugins
  end
end
