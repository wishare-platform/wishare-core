class UsersController < ApplicationController
  include SeoHelper

  before_action :set_user, only: [:show]

  def show
    # Load wishlists based on viewer permissions
    if current_user == @user
      @wishlists = @user.wishlists.includes(:wishlist_items).with_attached_cover_image
    elsif current_user && Connection.between_users(@user, current_user)&.accepted?
      @wishlists = @user.wishlists.visible_to_friends.includes(:wishlist_items).with_attached_cover_image
    else
      @wishlists = @user.wishlists.public_lists.includes(:wishlist_items).with_attached_cover_image
    end

    @public_wishlists = @user.wishlists.public_lists.includes(:wishlist_items).with_attached_cover_image

    # Load stats for profile header
    @stats = {
      wishlists_count: @user.wishlists.count,
      friends_count: @user.connections.accepted.count,
      items_count: @user.wishlists.sum(:wishlist_items_count)
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
