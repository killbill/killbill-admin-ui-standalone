class MainController < ApplicationController

  def available_engines
    render :json => find_available_plugins
  end

  private

  def find_available_plugins
    plugins = []

    nodes_info = KillBillClient::Model::NodesInfo.nodes_info(options_for_klient) || []
    plugins_info = nodes_info.first.plugins_info || []

    plugins_info.each do |plugin_info|
      next unless plugin_info.state == 'RUNNING'
      next unless Kaui.plugins_whitelist.nil? || Kaui.plugins_whitelist.include?(plugin_info.plugin_name)

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
      elsif plugin_info.plugin_name == 'killbill-kpm' && current_user.root?
        plugins << {
            :path => kpm_engine_path,
            :name => 'KPM'
        }
      elsif plugin_info.bundle_symbolic_name == 'org.apache.felix.webconsole' && current_user.root?
        plugins << {
            :path => "#{KillBillClient.url}/plugins/system/console/bundles",
            :name => 'OSGI Web Console'
        }
      end
    end

    plugins
  end

end
