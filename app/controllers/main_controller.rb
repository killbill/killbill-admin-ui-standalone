class MainController < ApplicationController

  def available_engines
    render :json => find_available_plugins
  end

  private

  def find_available_plugins
    plugins = []

    KillBillClient::Model::PluginInfo.plugins_info(options_for_klient).each do |plugin_info|
      next unless plugin_info.running

      if plugin_info.plugin_name == 'analytics-plugin'
        plugins << {
            :path => kanaui_engine_path,
            :name => 'Analytics'
        }
      elsif plugin_info.plugin_name == 'avatax-plugin'
        plugins << {
            :path => avatax_engine_path,
            :name => 'Avatax'
        }
      elsif plugin_info.bundle_symbolic_name == 'org.apache.felix.webconsole'
        plugins << {
            :path => "#{KillBillClient.url}/plugins/system/console/bundles",
            :name => 'OSGI Web Console'
        }
      end
    end

    plugins
  end

end
