require "test_helper"

class Mobile::MobileAuthControllerTest < ActionDispatch::IntegrationTest
  test "session_check returns unauthenticated when not signed in" do
    get mobile_auth_session_check_path, as: :json
    assert_response :unauthorized

    body = JSON.parse(response.body)
    assert_equal "unauthenticated", body["status"]
  end

  test "session_check returns authenticated for signed in user" do
    user = create(:user)
    sign_in user

    get mobile_auth_session_check_path, as: :json
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal "authenticated", body["status"]
    assert_equal user.id, body["user_id"]
  end

  test "app_config returns feature flags and supported locales" do
    get mobile_auth_config_path, as: :json
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal "ok", body["status"]
    assert body["data"]["features"]["push_notifications"]
    assert_includes body["data"]["supported_locales"], "en"
    assert_includes body["data"]["supported_locales"], "pt-BR"
  end

  test "health returns ok when database is accessible" do
    get mobile_health_path, as: :json
    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal "ok", body["status"]
    assert body["database"]
  end
end
