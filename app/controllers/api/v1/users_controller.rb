# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:show]
      before_action :set_user, only: [:show]

      def profile
        render json: user_with_stats(current_user)
      end

      def update_profile
        if current_user.update(user_params)
          render json: user_with_stats(current_user)
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        # Public profile endpoint
        render json: public_user_json(@user)
      end

      def update_avatar
        if params[:avatar].present?
          current_user.avatar_url = params[:avatar]
          if current_user.save
            render json: { message: 'Avatar updated', avatar_url: current_user.avatar_url }
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'No avatar provided' }, status: :bad_request
        end
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end

      def user_params
        params.require(:user).permit(:name, :email, :preferred_locale, :date_of_birth,
                                      :address_line_1, :address_line_2, :address_number,
                                      :address_apartment, :city, :state, :postal_code,
                                      :country, :address_visibility)
      end

      def user_with_stats(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          avatar_url: user.avatar_url,
          preferred_locale: user.preferred_locale,
          date_of_birth: user.date_of_birth,
          role: user.role,
          created_at: user.created_at,
          address: {
            line_1: user.address_line_1,
            line_2: user.address_line_2,
            number: user.address_number,
            apartment: user.address_apartment,
            city: user.city,
            state: user.state,
            postal_code: user.postal_code,
            country: user.country,
            visibility: user.address_visibility
          },
          stats: {
            wishlists_count: user.wishlists.count,
            connections_count: user.all_connections.accepted.count,
            items_count: user.wishlists.joins(:items).count,
            notifications_unread: user.notifications.unread.count
          }
        }
      end

      def public_user_json(user)
        {
          id: user.id,
          name: user.name,
          avatar_url: user.avatar_url,
          created_at: user.created_at,
          public_wishlists: user.wishlists.publicly_visible.map do |w|
            {
              id: w.id,
              name: w.name,
              description: w.description,
              event_type: w.event_type,
              event_date: w.event_date,
              items_count: w.items.count
            }
          end
        }
      end
    end
  end
end