# frozen_string_literal: true

module Api
  module V1
    class WishlistsController < BaseController
      before_action :set_wishlist, only: [:show, :update, :destroy]

      def index
        wishlists = current_user.wishlists.includes(:items)
        render json: wishlists.map { |w| wishlist_json(w) }
      end

      def show
        if can_view_wishlist?(@wishlist)
          render json: wishlist_json(@wishlist, include_items: true)
        else
          render json: { error: 'Not authorized' }, status: :forbidden
        end
      end

      def create
        wishlist = current_user.wishlists.build(wishlist_params)

        if wishlist.save
          render json: wishlist_json(wishlist), status: :created
        else
          render json: { errors: wishlist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @wishlist.update(wishlist_params)
          render json: wishlist_json(@wishlist)
        else
          render json: { errors: @wishlist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @wishlist.destroy
        render json: { message: 'Wishlist deleted successfully' }, status: :ok
      end

      private

      def set_wishlist
        @wishlist = current_user.wishlists.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Wishlist not found' }, status: :not_found
      end

      def wishlist_params
        params.require(:wishlist).permit(:name, :description, :visibility, :event_type, :event_date, :is_default)
      end

      def can_view_wishlist?(wishlist)
        return true if wishlist.user == current_user
        return true if wishlist.publicly_visible?
        return true if wishlist.friends_and_family? && current_user.connected_with?(wishlist.user)
        false
      end

      def wishlist_json(wishlist, include_items: false)
        json = {
          id: wishlist.id,
          name: wishlist.name,
          description: wishlist.description,
          visibility: wishlist.visibility,
          event_type: wishlist.event_type,
          event_date: wishlist.event_date,
          is_default: wishlist.is_default,
          items_count: wishlist.items.count,
          created_at: wishlist.created_at,
          updated_at: wishlist.updated_at
        }

        if include_items
          json[:items] = wishlist.items.map do |item|
            {
              id: item.id,
              name: item.name,
              description: item.description,
              price: item.price,
              currency: item.currency,
              url: item.url,
              image_url: item.image_url,
              priority: item.priority,
              purchased: item.purchased?,
              purchased_at: item.purchased_at
            }
          end
        end

        json
      end
    end
  end
end