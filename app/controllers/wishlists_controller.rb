class WishlistsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_wishlist, only: [:show, :edit, :update, :destroy]
  before_action :ensure_authenticated_for_private_wishlists, only: [:show]

  def index
    @wishlists = current_user.wishlists.includes(:wishlist_items)
    @partner = current_user.partner
    # Include both partner_only and public wishlists from connected users
    if @partner
      partner_wishlists = @partner.wishlists.where(visibility: [:partner_only, :publicly_visible]).includes(:wishlist_items)
      @partner_wishlists = partner_wishlists
    else
      @partner_wishlists = []
    end
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

  def ensure_authenticated_for_private_wishlists
    return if @wishlist.publicly_visible?
    authenticate_user!
  end

  def can_view_wishlist?(wishlist)
    return true if wishlist.user == current_user
    return true if wishlist.publicly_visible?
    return false if wishlist.private_list?
    return false unless current_user&.connected_to?(wishlist.user)
    
    wishlist.partner_only?
  end
end