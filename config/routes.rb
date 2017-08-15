# See https://github.com/rails/rails/blob/c0a1dc256144b91aee5241fad2121e85e6d8093f/actionpack/test/dispatch/prefix_generation_test.rb#L278
KauiStandalone::Application.routes.default_url_options = {script_name: ActionController::Base.relative_url_root.to_s}

Rails.application.routes.draw do

  # We mount KAUI as root, since this is the primary engine
  mount Kaui::Engine => '/', :as => 'kaui_engine'

  mount Kanaui::Engine => '/analytics', :as => 'kanaui_engine'
  mount Avatax::Engine => '/avatax', :as => 'avatax_engine'
  mount KPM::Engine => '/kpm', :as => 'kpm_engine'
  mount PaymentTest::Engine => '/payment_test', :as => 'payment_test_engine'

  scope '/main' do
    match '/available_engines' => 'main#available_engines', :via => :get, :as => 'available_engines'
  end

  root :to => 'home#index'
end
