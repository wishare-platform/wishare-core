class Mobile::MobileAuthController < ActionController::Base
  # Use the same session/cookie store as the main app so Devise sessions work
  include ActionController::Cookies

  # Devise helpers for session-based auth (Hotwire Native uses cookies, not JWT)
  include Devise::Controllers::Helpers

  # Skip CSRF for mobile endpoints — Hotwire Native doesn't send CSRF tokens
  skip_before_action :verify_authenticity_token

  # Check authentication status for mobile apps (cookie-based session)
  # iOS AuthBridge expects: { status: "authenticated", user_id: ..., email: ... }
  # or: { status: "unauthenticated" }
  def session_check
    if current_user
      render json: {
        status: "authenticated",
        user_id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        avatar_url: current_user.read_attribute(:avatar_url),
        preferred_locale: current_user.preferred_locale
      }
    else
      render json: { status: "unauthenticated" }, status: :unauthorized
    end
  end

  # Return authentication status with additional context
  def status
    if current_user
      render json: {
        status: "authenticated",
        user_id: current_user.id,
        email: current_user.email,
        name: current_user.name
      }
    else
      render json: { status: "unauthenticated" }, status: :unauthorized
    end
  end

  # Provide app configuration for mobile clients
  def app_config
    render json: {
      status: "ok",
      data: {
        api_url: ENV.fetch("HOST_URL", "http://localhost:3000"),
        min_app_version: "1.0.0",
        features: {
          push_notifications: true,
          biometric_auth: true,
          camera: true,
          dark_mode: true,
          offline_mode: false
        },
        supported_locales: %w[en pt-BR]
      }
    }
  end

  # Health check — verifies the app and database are responsive
  def health
    db_ok = begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      true
    rescue StandardError
      false
    end

    status_code = db_ok ? :ok : :service_unavailable

    render json: {
      status: db_ok ? "ok" : "degraded",
      database: db_ok,
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }, status: status_code
  end
end
