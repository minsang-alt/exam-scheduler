require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get login" do
    post api_v1_auth_login_url
    assert_response :unauthorized
  end

  test "should get register" do
    post api_v1_auth_register_url
    assert_response :unprocessable_entity
  end
end
