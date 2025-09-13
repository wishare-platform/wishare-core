# frozen_string_literal: true

module Api
  module V1
    class DeviceTokensController < BaseController
      before_action :set_device_token, only: [:show, :update, :destroy]

      def index
        tokens = current_user.device_tokens.active.order(updated_at: :desc)

        render json: {
          device_tokens: tokens.map { |token| device_token_json(token) },
          count: tokens.count
        }
      end

      def show
        render json: device_token_json(@device_token)
      end

      def create
        # Find existing token for this device or create new one
        existing_token = current_user.device_tokens.find_by(
          device_id: device_token_params[:device_id],
          platform: device_token_params[:platform]
        )

        if existing_token
          # Update existing token
          if existing_token.update(
            token: device_token_params[:token],
            app_version: device_token_params[:app_version],
            is_active: true,
            last_used_at: Time.current
          )
            render json: device_token_json(existing_token)
          else
            render json: { errors: existing_token.errors.full_messages }, status: :unprocessable_entity
          end
        else
          # Create new token
          device_token = current_user.device_tokens.build(device_token_params)
          device_token.last_used_at = Time.current

          if device_token.save
            render json: device_token_json(device_token), status: :created
          else
            render json: { errors: device_token.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      def update
        if @device_token.update(device_token_update_params)
          render json: device_token_json(@device_token)
        else
          render json: { errors: @device_token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @device_token.update(is_active: false)
        render json: { message: 'Device token deactivated' }
      end

      def test_notification
        # Send test push notification to user's devices
        active_tokens = current_user.device_tokens.active

        if active_tokens.empty?
          render json: { error: 'No active device tokens found' }, status: :bad_request
          return
        end

        notification_data = {
          title: 'Test Notification',
          body: 'This is a test notification from Wishare API',
          data: {
            type: 'test',
            timestamp: Time.current.iso8601
          }
        }

        success_count = 0
        active_tokens.each do |token|
          begin
            PushNotificationService.send_notification(token, notification_data)
            success_count += 1
          rescue => e
            Rails.logger.error "Failed to send test notification to token #{token.id}: #{e.message}"
          end
        end

        render json: {
          message: "Test notification sent to #{success_count} device(s)",
          total_devices: active_tokens.count,
          successful_sends: success_count
        }
      end

      private

      def set_device_token
        @device_token = current_user.device_tokens.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Device token not found' }, status: :not_found
      end

      def device_token_params
        params.require(:device_token).permit(:token, :platform, :device_id, :device_name, :app_version)
      end

      def device_token_update_params
        params.require(:device_token).permit(:device_name, :app_version, :is_active)
      end

      def device_token_json(device_token)
        {
          id: device_token.id,
          token: device_token.token&.first(20) + '...', # Truncate for security
          platform: device_token.platform,
          device_id: device_token.device_id,
          device_name: device_token.device_name,
          app_version: device_token.app_version,
          is_active: device_token.is_active,
          last_used_at: device_token.last_used_at,
          created_at: device_token.created_at,
          updated_at: device_token.updated_at
        }
      end
    end
  end
end