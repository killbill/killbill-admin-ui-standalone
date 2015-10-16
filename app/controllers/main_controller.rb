class MainController < ActionController::Base

  def available_engines
    plugins = [
        {
            :path => kanaui_engine_path,
            :name => 'Analytics'
        },
        {
            :path => avatax_engine_path,
            :name => 'Avatax'
        }
    ]
    render :json => plugins
  end

end
