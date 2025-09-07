class WishlistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wishlist, only: [:show, :edit, :update, :destroy]

  def index
    @wishlists = current_user.wishlists.includes(:wishlist_items)
    @partner = current_user.partner
    @partner_wishlists = @partner&.wishlists&.partner_only&.includes(:wishlist_items) || []
    @focus_partner = params[:partner] == 'true'
  end

  def show
    unless can_view_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to view this wishlist.'
      return
    end

    @wishlist_items = @wishlist.wishlist_items.includes(:purchased_by)
  end

  def new
    @wishlist = current_user.wishlists.build
  end

  def create
    @wishlist = current_user.wishlists.build(wishlist_params)
    @wishlist.visibility = :partner_only unless @wishlist.visibility.present?

    if @wishlist.save
      redirect_to @wishlist, notice: 'Wishlist was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @wishlist.update(wishlist_params)
      redirect_to @wishlist, notice: 'Wishlist was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wishlist.destroy
    redirect_to wishlists_path, notice: 'Wishlist was successfully deleted.'
  end

  private

  def set_wishlist
    @wishlist = Wishlist.find(params[:id])
  end

  def wishlist_params
    params.require(:wishlist).permit(:name, :description, :is_default, :visibility)
  end

  def can_view_wishlist?(wishlist)
    return true if wishlist.user == current_user
    return false if wishlist.private_list?
    return false unless current_user.connected_to?(wishlist.user)
    
    wishlist.partner_only?
  end
end