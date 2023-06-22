# frozen_string_literal: true

require 'test_helper'

class HomepageTest < ActionDispatch::IntegrationTest
  BASE_PATH = ''
  TENANTS_PATH = "#{BASE_PATH}/tenants"
  SIGN_IN_PATH  = "#{BASE_PATH}/users/sign_in"
  SIGN_OUT_PATH = "#{BASE_PATH}/users/sign_out"
  USERNAME = 'admin'
  PASSWORD = 'password'

  test 'Login' do
    # Verify log-in
    post SIGN_IN_PATH, params: { user: { kb_username: USERNAME, password: PASSWORD } }
    assert_redirected_to TENANTS_PATH

    # Verify log-out
    delete SIGN_OUT_PATH
    assert_redirected_to "#{BASE_PATH}/"

    get BASE_PATH
    assert_redirected_to SIGN_IN_PATH
    assert_equal 'You need to sign in before continuing.', flash[:alert]
  end
end
