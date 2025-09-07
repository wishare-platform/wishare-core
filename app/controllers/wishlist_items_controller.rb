class WishlistItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wishlist
  before_action :set_wishlist_item, only: [:show, :edit, :update, :destroy, :purchase, :unpurchase]

  def show
    unless can_view_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to view this wishlist.'
      return
    end
  end

  def new
    unless can_edit_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to add items to this wishlist.'
      return
    end

    @wishlist_item = @wishlist.wishlist_items.build
    @wishlist_item.priority = :medium
    @wishlist_item.status = :available
  end

  def create
    unless can_edit_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to add items to this wishlist.'
      return
    end

    @wishlist_item = @wishlist.wishlist_items.build(wishlist_item_params)
    @wishlist_item.priority = :medium unless @wishlist_item.priority.present?
    @wishlist_item.status = :available

    if @wishlist_item.save
      redirect_to [@wishlist, @wishlist_item], notice: 'Item was successfully added to your wishlist.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless can_edit_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to edit this item.'
      return
    end
  end

  def update
    unless can_edit_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to edit this item.'
      return
    end

    if @wishlist_item.update(wishlist_item_params)
      redirect_to [@wishlist, @wishlist_item], notice: 'Item was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless can_edit_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to delete this item.'
      return
    end

    @wishlist_item.destroy
    redirect_to @wishlist, notice: 'Item was successfully removed from the wishlist.'
  end

  def purchase
    unless can_purchase_item?(@wishlist_item)
      redirect_to @wishlist, alert: 'You do not have permission to purchase this item.'
      return
    end

    @wishlist_item.update!(
      status: :purchased,
      purchased_by: current_user,
      purchased_at: Time.current
    )

    redirect_to @wishlist, notice: 'Item marked as purchased!'
  end

  def unpurchase
    unless can_unpurchase_item?(@wishlist_item)
      redirect_to @wishlist, alert: 'You do not have permission to unpurchase this item.'
      return
    end

    @wishlist_item.update!(
      status: :available,
      purchased_by: nil,
      purchased_at: nil
    )

    redirect_to @wishlist, notice: 'Item marked as available again.'
  end

  private

  def set_wishlist
    @wishlist = Wishlist.find(params[:wishlist_id])
  end

  def set_wishlist_item
    @wishlist_item = @wishlist.wishlist_items.find(params[:id])
  end

  def wishlist_item_params
    params.require(:wishlist_item).permit(:name, :description, :price, :url, :image_url, :priority)
  end

  def can_view_wishlist?(wishlist)
    return true if wishlist.user == current_user
    return false if wishlist.private_list?
    return false unless current_user.connected_to?(wishlist.user)
    
    wishlist.partner_only?
  end

  def can_edit_wishlist?(wishlist)
    wishlist.user == current_user
  end

  def can_purchase_item?(item)
    # Only partners can purchase items, and they can't purchase from their own wishlist
    return false if item.wishlist.user == current_user
    return false unless current_user.connected_to?(item.wishlist.user)
    return false unless item.available?
    
    true
  end

  def can_unpurchase_item?(item)
    # Only the person who purchased the item can unpurchase it
    item.purchased_by == current_user
  end
end