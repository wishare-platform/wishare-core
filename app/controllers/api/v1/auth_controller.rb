# frozen_string_literal: true

require 'jwt'

module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [:login, :refresh_token]

      def login
        user = User.find_by(email: login_params[:email])

        if user&.valid_password?(login_params[:password])
          tokens = generate_auth_token(user)
          render json: {
            user: user_json(user),
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token],
            expires_in: tokens[:expires_in],
            message: 'Logged in successfully'
          }, status: :ok
        else
          render json: {
            error: 'Invalid email or password'
          }, status: :unauthorized
        end
      end

      def logout
        token = request.headers['Authorization']&.gsub('Bearer ', '')

        if token.present?
          begin
            payload = JWT.decode(token, jwt_secret, true, { algorithm: 'HS256' })[0]
            # Add token to denylist
            JwtDenylist.create!(
              jti: payload['jti'],
              user_id: payload['user_id'],
              exp: Time.at(payload['exp'])
            )
          rescue JWT::DecodeError => e
            Rails.logger.error "Logout token decode error: #{e.message}"
          end
        end

        render json: {
          message: 'Logged out successfully'
        }, status: :ok
      end

      def refresh_token
        token = params[:refresh_token]

        if token.blank?
          render json: { error: 'Refresh token required' }, status: :bad_request
          return
        end

        begin
          payload = JWT.decode(token, jwt_secret, true, { algorithm: 'HS256' })[0]

          # Verify it's a refresh token
          unless payload['type'] == 'refresh'
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
            return
          end

          # Check if refresh token is blacklisted
          if JwtDenylist.exists?(jti: payload['jti'])
            render json: { error: 'Refresh token revoked' }, status: :unauthorized
            return
          end

          user = User.find(payload['user_id'])

          # Generate new access token
          new_tokens = generate_auth_token(user)

          # Optionally revoke old refresh token
          JwtDenylist.create!(
            jti: payload['jti'],
            user: user,
            exp: Time.at(payload['exp'])
          )

          render json: {
            user: user_json(user),
            access_token: new_tokens[:access_token],
            refresh_token: new_tokens[:refresh_token],
            expires_in: new_tokens[:expires_in],
            message: 'Token refreshed successfully'
          }, status: :ok

        rescue JWT::ExpiredSignature
          render json: { error: 'Refresh token expired' }, status: :unauthorized
        rescue JWT::DecodeError, JWT::VerificationError
          render json: { error: 'Invalid refresh token' }, status: :unauthorized
        rescue ActiveRecord::RecordNotFound
          render json: { error: 'User not found' }, status: :unauthorized
        end
      end

      def validate_token
        if current_user
          render json: {
            valid: true,
            user: user_json(current_user)
          }, status: :ok
        else
          render json: {
            valid: false,
            error: 'Invalid or expired token'
          }, status: :unauthorized
        end
      end

      private

      def login_params
        params.require(:user).permit(:email, :password)
      end

      def generate_auth_token(user)
        # Generate proper JWT with shorter expiration + refresh token
        payload = {
          user_id: user.id,
          exp: 24.hours.from_now.to_i,  # Access token: 24 hours
          iat: Time.current.to_i,
          jti: SecureRandom.uuid       # Unique token ID for revocation
        }

        access_token = JWT.encode(payload, jwt_secret, 'HS256')
        refresh_token = generate_refresh_token(user)

        {
          access_token: access_token,
          refresh_token: refresh_token,
          expires_in: 24.hours.to_i
        }
      end

      def generate_refresh_token(user)
        # Refresh tokens last longer (7 days) and are stored in DB
        jti = SecureRandom.uuid
        payload = {
          user_id: user.id,
          exp: 7.days.from_now.to_i,
          iat: Time.current.to_i,
          jti: jti,
          type: 'refresh'
        }

        # Store refresh token in denylist for tracking
        JwtDenylist.create!(
          jti: jti,
          user: user,
          exp: 7.days.from_now
        )

        JWT.encode(payload, jwt_secret, 'HS256')
      end

      def jwt_secret
        ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          name: user.name,
          avatar_url: user.avatar_url,
          preferred_locale: user.preferred_locale
        }
      end
    end
  end
end