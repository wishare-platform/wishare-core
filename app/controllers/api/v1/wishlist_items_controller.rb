# frozen_string_literal: true

module Api
  module V1
    class WishlistItemsController < BaseController
      before_action :set_wishlist
      before_action :set_item, only: [:show, :update, :destroy, :toggle_purchase]

      def index
        render json: @wishlist.items.map { |item| item_json(item) }
      end

      def show
        render json: item_json(@item)
      end

      def create
        item = @wishlist.items.build(item_params)

        if item.save
          render json: item_json(item), status: :created
        else
          render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @item.update(item_params)
          render json: item_json(@item)
        else
          render json: { errors: @item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @item.destroy
        render json: { message: 'Item deleted successfully' }, status: :ok
      end

      def toggle_purchase
        if @item.purchased?
          @item.update(purchased_by: nil, purchased_at: nil)
          render json: { message: 'Item marked as not purchased', item: item_json(@item) }
        else
          @item.update(purchased_by: current_user, purchased_at: Time.current)
          render json: { message: 'Item marked as purchased', item: item_json(@item) }
        end
      end

      private

      def set_wishlist
        @wishlist = Wishlist.find(params[:wishlist_id])

        unless can_manage_wishlist?(@wishlist)
          render json: { error: 'Not authorized' }, status: :forbidden
        end
      end

      def set_item
        @item = @wishlist.items.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Item not found' }, status: :not_found
      end

      def item_params
        params.require(:item).permit(:name, :description, :price, :currency, :url, :image_url, :priority)
      end

      def can_manage_wishlist?(wishlist)
        return true if wishlist.user == current_user
        return true if wishlist.friends_and_family? && current_user.connected_with?(wishlist.user)
        return true if wishlist.publicly_visible?
        false
      end

      def item_json(item)
        {
          id: item.id,
          wishlist_id: item.wishlist_id,
          name: item.name,
          description: item.description,
          price: item.price,
          currency: item.currency,
          formatted_price: item.formatted_price,
          url: item.url,
          image_url: item.image_url,
          priority: item.priority,
          purchased: item.purchased?,
          purchased_by_id: item.purchased_by_id,
          purchased_at: item.purchased_at,
          created_at: item.created_at,
          updated_at: item.updated_at
        }
      end
    end
  end
end