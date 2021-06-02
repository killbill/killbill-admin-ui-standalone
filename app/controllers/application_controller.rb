# All engines will inherit from this controller (naming convention)
class ApplicationController < ActionController::Base

  layout Kaui.config[:layout]

  protect_from_forgery

  before_action :populate_mdc_context, :authenticate_user!, :check_for_redirect_to_tenant_screen
  after_action :clear_mdc_context

  def check_for_redirect_to_tenant_screen
    unless Kaui.is_user_assigned_valid_tenant?(current_user, session)
      if params[:format] == 'json'
        # While technically true, the :bad_request status would display a flash error, which can be confusing for the user
        # render :json => { :error => 'No tenant selected' }, :status => :bad_request
        render :json => { :error => 'No tenant selected' }
      else
        flash[:error] = 'Select a tenant'
        session[:kb_tenant_id] = nil
        redirect_to Kaui.tenant_home_path.call
      end
    end
  end

  # Common options for the Kill Bill client
  def options_for_klient(options = {})
    user_tenant_options = Kaui.current_tenant_user_options(current_user, session)
    user_tenant_options.merge!(options)
    user_tenant_options
  end

  def populate_mdc_context
    return unless KauiStandalone::WITH_LOGBACK

    org.slf4j.MDC.put('rails.actionName', "#{controller_name}##{action_name}")
    org.slf4j.MDC.put('req.xForwardedFor', request.headers['X-Forwarded-For'])
    org.slf4j.MDC.put('req.requestId', request.request_id)
    org.slf4j.MDC.put('kb.accountId', params[:account_id])
    org.slf4j.MDC.put('kb.tenantId', session[:kb_tenant_id])
  end

  def clear_mdc_context
    return unless KauiStandalone::WITH_LOGBACK

    %w(rails.actionName req.xForwardedFor req.requestId kb.accountId kb.tenantId).each do |key|
      org.slf4j.MDC.remove(key)
    end
  end
end
