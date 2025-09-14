class Admin::WishlistsController < Admin::BaseController
  before_action :set_wishlist, only: [:show, :destroy]
  before_action :require_super_admin!, only: [:destroy]
  
  def index
    @wishlists = Wishlist.includes(:user, :wishlist_items)
                        
    @wishlists = @wishlists.joins(:user)
                          .where("wishlists.name ILIKE ? OR users.name ILIKE ?", 
                                "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @wishlists = @wishlists.where(visibility: params[:visibility]) if params[:visibility].present?
    @wishlists = @wishlists.order(created_at: :desc)
    @wishlists = @wishlists.limit(25).offset((params[:page]&.to_i || 1 - 1) * 25)
    
    @total_wishlists = Wishlist.count
    @public_wishlists = Wishlist.publicly_visible.count
    @partner_only_wishlists = Wishlist.partner_only.count
    @private_wishlists = Wishlist.private_list.count
  end

  def show
    @items = @wishlist.wishlist_items.includes(:purchased_by)
  end

  def destroy
    if @wishlist.destroy
      redirect_to admin_wishlists_path, notice: 'Wishlist deleted successfully.'
    else
      redirect_to admin_wishlists_path, alert: 'Failed to delete wishlist.'
    end
  end

  private

  def set_wishlist
    @wishlist = Wishlist.find(params[:id])
  end
end