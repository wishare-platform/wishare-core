# frozen_string_literal: true

require 'jwt'

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
            payload = JWT.decode(token, jwt_secret, true, { algorithm: 'HS256' })[0]

            # Check if token is blacklisted
            if JwtDenylist.exists?(jti: payload['jti'])
              render json: { error: 'Token revoked' }, status: :unauthorized
              return
            end

            # Check expiration (JWT gem validates this, but double-check)
            if payload['exp'] > Time.current.to_i
              @current_user = User.find(payload['user_id'])
              return
            end
          rescue JWT::ExpiredSignature
            render json: { error: 'Token expired', code: 'TOKEN_EXPIRED' }, status: :unauthorized
            return
          rescue JWT::DecodeError, JWT::VerificationError => e
            Rails.logger.error "JWT decode error: #{e.message}"
            render json: { error: 'Invalid token' }, status: :unauthorized
            return
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'User not found' }, status: :unauthorized
            return
          end
        end

        render json: { error: 'Authentication required' }, status: :unauthorized
      end

      def jwt_secret
        ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base
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