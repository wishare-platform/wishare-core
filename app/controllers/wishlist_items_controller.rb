class WishlistItemsController < ApplicationController
  include SeoHelper

  before_action :authenticate_user!
  before_action :set_wishlist, except: [:extract_url_metadata]
  before_action :set_wishlist_item, only: [:show, :edit, :update, :destroy, :purchase, :unpurchase]

  def show
    unless can_view_wishlist?(@wishlist)
      redirect_to wishlists_path, alert: 'You do not have permission to view this wishlist.'
      return
    end

    # Set meta tags for wishlist item
    @seo_title = wishlist_item_meta_title(@wishlist_item)
    @seo_description = wishlist_item_meta_description(@wishlist_item)
    @seo_image = meta_image_url(@wishlist_item)
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
      # Track item addition activity
      ActivityTrackerService.track_item_added(
        user: current_user,
        item: @wishlist_item,
        request: request
      )

      redirect_to @wishlist, notice: 'Item was successfully added to your wishlist.'
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
      redirect_to @wishlist, notice: 'Item was successfully updated.'
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

    # Create notification for wishlist owner
    NotificationService.new.create_item_purchase_notification(
      user: @wishlist.user,
      purchaser: current_user,
      wishlist_item: @wishlist_item,
      wishlist: @wishlist
    )

    # Track item purchase activity
    ActivityTrackerService.track_item_purchased(
      purchaser: current_user,
      item: @wishlist_item,
      request: request
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

  def extract_url_metadata
    url = params[:url]

    if url.blank?
      render json: { error: 'URL is required' }, status: :bad_request
      return
    end

    begin
      # Use the new master extractor with intelligent fallbacks
      options = {
        skip_api: params[:skip_api] == 'true', # Allow skipping API calls if needed
        skip_methods: params[:skip_methods]&.split(',')&.map(&:to_sym) || []
      }

      metadata = MasterUrlMetadataExtractor.new(url, options).extract

      # If extraction is taking too long, return partial data and continue in background
      if metadata.blank? || (!metadata[:title] && !metadata[:description])
        # Return what we have and continue extraction in background
        MetadataExtractionJob.perform_later(url) if defined?(MetadataExtractionJob)

        # Try basic extraction for immediate response
        metadata = UrlMetadataExtractor.new(url).extract
      end

      render json: metadata
    rescue => e
      Rails.logger.warn "URL metadata extraction failed for #{url}: #{e.message}"

      # Fallback to basic extractor
      begin
        metadata = UrlMetadataExtractor.new(url).extract
        render json: metadata
      rescue => fallback_error
        Rails.logger.error "All extraction methods failed for #{url}: #{fallback_error.message}"
        render json: { error: 'Failed to extract metadata' }, status: :unprocessable_entity
      end
    end
  end

  private

  def set_wishlist
    @wishlist = Wishlist.find_by(id: params[:wishlist_id])
    render_404 and return unless @wishlist
  end

  def set_wishlist_item
    @wishlist_item = @wishlist.wishlist_items.find_by(id: params[:id])
    render_404 and return unless @wishlist_item
  end

  def wishlist_item_params
    params.require(:wishlist_item).permit(:name, :description, :price, :currency, :url, :image_url, :priority)
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