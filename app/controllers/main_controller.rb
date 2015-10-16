class MainController < ActionController::Base

  def available_engines
    plugins = [
        {
            :path => kanaui_engine_path,
            :name => 'Analytics'
        }
    ]
    render :json => plugins
  end

end
