# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [:login]

      def login
        user = User.find_by(email: login_params[:email])

        if user&.valid_password?(login_params[:password])
          # Generate simple token (for now, using Rails.application.secret_key_base)
          token = generate_auth_token(user)
          render json: {
            user: user_json(user),
            token: token,
            message: 'Logged in successfully'
          }, status: :ok
        else
          render json: {
            error: 'Invalid email or password'
          }, status: :unauthorized
        end
      end

      def logout
        render json: {
          message: 'Logged out successfully'
        }, status: :ok
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
        # Simple token generation - in production, use proper JWT
        payload = {
          user_id: user.id,
          exp: 7.days.from_now.to_i
        }
        Base64.encode64(payload.to_json).strip
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