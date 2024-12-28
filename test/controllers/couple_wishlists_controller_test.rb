require "test_helper"

class CoupleWishlistsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get couple_wishlists_index_url
    assert_response :success
  end

  test "should get show" do
    get couple_wishlists_show_url
    assert_response :success
  end

  test "should get new" do
    get couple_wishlists_new_url
    assert_response :success
  end

  test "should get create" do
    get couple_wishlists_create_url
    assert_response :success
  end

  test "should get edit" do
    get couple_wishlists_edit_url
    assert_response :success
  end

  test "should get update" do
    get couple_wishlists_update_url
    assert_response :success
  end

  test "should get destroy" do
    get couple_wishlists_destroy_url
    assert_response :success
  end
end
