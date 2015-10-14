class ApplicationController < ActionController::Base

  layout Kaui.config[:layout]

  # TODO Need to be redefined here for some reason
  def current_ability
    # Redefined here to namespace Ability in the correct module
    @current_ability ||= Kaui::Ability.new(current_user)
  end

  protect_from_forgery

  before_filter :authenticate_user!, :check_for_redirect_to_tenant_screen

  def check_for_redirect_to_tenant_screen
    if !Kaui.is_user_assigned_valid_tenant?(current_user, session)
      flash[:error] = 'No tenants configured for users AND KillBillClient.api_key, KillBillClient.api_secret have not been set'
      session[:kb_tenant_id] = nil
      redirect_to Kaui.tenant_home_path.call and return
    end
  end

end
