# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::MimeResponds

      before_action :configure_permitted_parameters, if: :devise_controller?
      before_action :authenticate_user!

      respond_to :json

      # Override Devise's redirect to return JSON error instead
      def authenticate_user!
        token = request.headers['Authorization']&.gsub('Bearer ', '')

        if token.present?
          begin
            payload = JSON.parse(Base64.decode64(token))
            if payload['exp'] > Time.current.to_i
              @current_user = User.find(payload['user_id'])
              return
            end
          rescue => e
            Rails.logger.error "Token decode error: #{e.message}"
          end
        end

        render json: { error: 'Authentication required' }, status: :unauthorized
      end

      def current_user
        @current_user
      end

      def user_signed_in?
        current_user.present?
      end

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def record_not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
      end

      def current_locale
        current_user&.preferred_locale || I18n.default_locale
      end
    end
  end
end