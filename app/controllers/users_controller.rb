class UsersController < ApplicationController
  include SeoHelper

  before_action :set_user, only: [:show]

  def show
    # Load wishlists based on viewer permissions
    if current_user == @user
      @wishlists = @user.wishlists.includes(:wishlist_items)
    elsif current_user && Connection.between_users(@user, current_user)&.accepted?
      @wishlists = @user.wishlists.visible_to_friends.includes(:wishlist_items)
    else
      @wishlists = @user.wishlists.public_lists.includes(:wishlist_items)
    end

    @public_wishlists = @user.wishlists.public_lists.includes(:wishlist_items)

    # Load stats for profile header
    @stats = {
      wishlists_count: @user.wishlists.count,
      friends_count: @user.connections.accepted.count,
      items_count: @user.wishlists.joins(:wishlist_items).count('wishlist_items.id')
    }

    # Get available event types for filtering
    @available_event_types = @wishlists.where.not(event_type: [nil, '']).distinct.pluck(:event_type)

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