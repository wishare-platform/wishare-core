class WishlistsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_wishlist, only: [:show, :edit, :update, :destroy]
  before_action :ensure_authenticated_for_private_wishlists, only: [:show]

  def index
    @wishlists = current_user.wishlists.includes(:wishlist_items)
    
    # Get all connected users
    connected_user_ids = current_user.accepted_connections.map do |connection|
      connection.other_user(current_user).id
    end
    
    # Get wishlists from all connected users (friends_and_family and public)
    if connected_user_ids.any?
      @connected_wishlists = Wishlist.where(user_id: connected_user_ids)
                                     .where(visibility: [:partner_only, :publicly_visible])
                                     .includes(:user, :wishlist_items)
    else
      @connected_wishlists = []
    end
    
    # Also get all public wishlists from non-connected users
    @public_wishlists = Wishlist.where(visibility: :publicly_visible)
                                .where.not(user_id: [current_user.id] + connected_user_ids)
                                .includes(:user, :wishlist_items)
    
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
    
    # If this is the user's first wishlist, make it default
    if current_user.wishlists.empty?
      @wishlist.is_default = true
    end

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
    unless @wishlist.user == current_user
      redirect_to wishlists_path, alert: 'You can only delete your own wishlists.'
      return
    end
    
    @wishlist.destroy
    redirect_to wishlists_path, notice: 'Wishlist was successfully deleted.'
  end

  private

  def set_wishlist
    @wishlist = Wishlist.find(params[:id])
  end

  def wishlist_params
    params.require(:wishlist).permit(:name, :description, :is_default, :visibility, :event_type, :event_date)
  end

  def ensure_authenticated_for_private_wishlists
    return if @wishlist.publicly_visible?
    authenticate_user!
  end

  def can_view_wishlist?(wishlist)
    return true if wishlist.user == current_user
    return true if wishlist.publicly_visible?
    return false if wishlist.private_list?
    
    # For friends_and_family visibility (currently partner_only in the enum)
    if wishlist.partner_only?
      return current_user&.connected_to?(wishlist.user)
    end
    
    false
  end
end