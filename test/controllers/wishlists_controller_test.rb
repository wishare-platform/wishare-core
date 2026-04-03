require "test_helper"

class WishlistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "index shows user wishlists" do
    create(:wishlist, user: @user, name: "My Birthday")
    get wishlists_path(locale: "en")
    assert_response :success
  end

  test "index requires authentication" do
    sign_out @user
    get wishlists_path(locale: "en")
    assert_response :redirect
  end

  test "show displays public wishlist without auth" do
    sign_out @user
    wishlist = create(:wishlist, visibility: :publicly_visible)
    get wishlist_path(id: wishlist.id, locale: "en")
    assert_response :success
  end

  test "show blocks private wishlist from non-owner" do
    other_user = create(:user)
    wishlist = create(:wishlist, :private, user: other_user)
    get wishlist_path(id: wishlist.id, locale: "en")
    assert_redirected_to wishlists_path(locale: "en")
  end

  test "show allows owner to see private wishlist" do
    wishlist = create(:wishlist, :private, user: @user)
    get wishlist_path(id: wishlist.id, locale: "en")
    assert_response :success
  end

  test "show allows connected user to see friends-only wishlist" do
    friend = create(:user)
    create(:connection, user: @user, partner: friend, status: :accepted)
    wishlist = create(:wishlist, :friends_only, user: friend)
    get wishlist_path(id: wishlist.id, locale: "en")
    assert_response :success
  end

  test "show blocks non-connected user from friends-only wishlist" do
    stranger = create(:user)
    wishlist = create(:wishlist, :friends_only, user: stranger)
    get wishlist_path(id: wishlist.id, locale: "en")
    assert_redirected_to wishlists_path(locale: "en")
  end

  test "create builds wishlist for current user" do
    assert_difference "Wishlist.count", 1 do
      post wishlists_path(locale: "en"), params: { wishlist: { name: "New List", visibility: "publicly_visible" } }
    end
    assert_response :redirect
  end

  test "create rejects invalid wishlist" do
    assert_no_difference "Wishlist.count" do
      post wishlists_path(locale: "en"), params: { wishlist: { name: "", visibility: "publicly_visible" } }
    end
    assert_response :unprocessable_content
  end

  test "destroy removes own wishlist" do
    wishlist = create(:wishlist, user: @user)
    assert_difference "Wishlist.count", -1 do
      delete wishlist_path(id: wishlist.id, locale: "en")
    end
    assert_redirected_to wishlists_path(locale: "en")
  end

  test "destroy prevents deleting other user wishlist" do
    other_wishlist = create(:wishlist)
    assert_no_difference "Wishlist.count" do
      delete wishlist_path(id: other_wishlist.id, locale: "en")
    end
    assert_redirected_to wishlists_path(locale: "en")
  end
end
