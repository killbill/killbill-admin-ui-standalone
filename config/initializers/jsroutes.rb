JsRoutes.setup do |config|
  config.prefix = ActionController::Base.relative_url_root.to_s
  config.url_links = true
end
