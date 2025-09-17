class UsersController < ApplicationController
  include SeoHelper

  before_action :set_user, only: [:show]

  def show
    @public_wishlists = @user.wishlists.public_lists.includes(:wishlist_items)

    # Load stats for profile header
    @stats = {
      wishlists_count: @user.wishlists.count,
      friends_count: @user.connections.accepted.count,
      items_count: @user.wishlists.joins(:wishlist_items).count('wishlist_items.id')
    }

    # Set meta tags for user profile
    @seo_title = user_meta_title(@user)
    @seo_description = user_meta_description(@user)
    @seo_image = meta_image_url(@user)
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    render_404 and return unless @user
  end
end