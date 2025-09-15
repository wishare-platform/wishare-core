class UsersController < ApplicationController
  before_action :set_user, only: [:show]

  def show
    @public_wishlists = @user.wishlists.public_lists.includes(:wishlist_items)
  end

  private

  def set_user
    @user = User.find_by(id: params[:id])
    render_404 and return unless @user
  end
end