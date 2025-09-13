# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      before_action :set_notification, only: [:show, :mark_as_read, :destroy]

      def index
        notifications = current_user.notifications
                                   .includes(:user)
                                   .order(created_at: :desc)
                                   .limit(params[:limit] || 50)

        render json: {
          notifications: notifications.map { |n| notification_json(n) },
          unread_count: current_user.notifications.unread.count
        }
      end

      def show
        render json: notification_json(@notification)
      end

      def mark_as_read
        if @notification.update(read_at: Time.current)
          render json: notification_json(@notification)
        else
          render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def mark_all_as_read
        current_user.notifications.unread.update_all(read_at: Time.current)
        render json: { message: 'All notifications marked as read' }
      end

      def destroy
        @notification.destroy
        render json: { message: 'Notification deleted' }
      end

      def unread_count
        render json: {
          count: current_user.notifications.unread.count
        }
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Notification not found' }, status: :not_found
      end

      def notification_json(notification)
        {
          id: notification.id,
          notification_type: notification.notification_type,
          title: notification.title,
          message: notification.message,
          read: notification.read?,
          read_at: notification.read_at,
          created_at: notification.created_at,
          data: notification.data,
          actions: notification_actions(notification)
        }
      end

      def notification_actions(notification)
        case notification.notification_type
        when 'invitation_received'
          [
            { text: 'Accept', action: 'accept_invitation', data: notification.data },
            { text: 'Decline', action: 'decline_invitation', data: notification.data }
          ]
        when 'invitation_accepted', 'invitation_declined'
          [
            { text: 'View Profile', action: 'view_profile', data: notification.data }
          ]
        when 'item_purchased'
          [
            { text: 'View Wishlist', action: 'view_wishlist', data: notification.data }
          ]
        else
          []
        end
      end
    end
  end
end