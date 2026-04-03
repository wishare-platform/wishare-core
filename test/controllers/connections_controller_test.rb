require "test_helper"

class ConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "index shows accepted connections" do
    friend = create(:user)
    create(:connection, user: @user, partner: friend, status: :accepted)
    get connections_path(locale: "en")
    assert_response :success
  end

  test "index requires authentication" do
    sign_out @user
    get connections_path(locale: "en")
    assert_response :redirect
  end

  test "destroy removes connection" do
    friend = create(:user)
    connection = create(:connection, user: @user, partner: friend, status: :accepted)
    assert_difference "Connection.count", -1 do
      delete connection_path(id: connection.id, locale: "en")
    end
    assert_redirected_to connections_path(locale: "en")
  end
end
