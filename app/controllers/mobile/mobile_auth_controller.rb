class Mobile::MobileAuthController < ApplicationController
  # Skip CSRF protection for mobile app
  skip_before_action :verify_authenticity_token, only: [:status, :session_check]

  # Check authentication status for mobile apps
  def status
    if user_signed_in?
      render json: {
        authenticated: true,
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          avatar_url: current_user.profile_avatar_url
        },
        dashboard_url: global_dashboard_path,
        timestamp: Time.current.iso8601
      }
    else
      render json: {
        authenticated: false,
        sign_in_url: new_user_session_path,
        sign_up_url: new_user_registration_path,
        timestamp: Time.current.iso8601
      }, status: :unauthorized
    end
  end

  # Enhanced session check for mobile apps
  def session_check
    Rails.logger.info "Mobile session check for IP: #{request.remote_ip}"
    Rails.logger.info "User Agent: #{request.user_agent}"
    Rails.logger.info "Current user: #{current_user&.id || 'none'}"

    if user_signed_in?
      # User is authenticated, provide full session info
      render json: {
        status: 'authenticated',
        user_id: current_user.id,
        session_valid: true,
        last_activity: current_user.updated_at.iso8601,
        expires_at: (Time.current + 24.hours).iso8601, # Session expires in 24 hours
        dashboard_url: global_dashboard_path,
        csrf_token: form_authenticity_token
      }
    else
      # User is not authenticated
      Rails.logger.warn "Mobile session check failed - user not authenticated"
      render json: {
        status: 'unauthenticated',
        session_valid: false,
        sign_in_url: new_user_session_path,
        message: 'Authentication required to access dashboard'
      }, status: :unauthorized
    end
  end

  # Provide app configuration for mobile clients
  def config
    render json: {
      api_version: '1.0',
      server_time: Time.current.iso8601,
      websocket_url: ActionCable.server.config.url || request.url.sub(/^http/, 'ws'),
      features: {
        real_time_updates: true,
        push_notifications: Rails.env.production?,
        offline_mode: false
      },
      endpoints: {
        dashboard: global_dashboard_path,
        sign_in: new_user_session_path,
        sign_out: destroy_user_session_path,
        api_base: '/api/v1'
      }
    }
  end

  # Health check for mobile apps
  def health
    render json: {
      status: 'ok',
      server_time: Time.current.iso8601,
      database_connected: ActiveRecord::Base.connected?,
      redis_connected: redis_connected?,
      version: Rails.application.class.module_parent_name.downcase
    }
  end

  private

  def redis_connected?
    Rails.cache.write('health_check', 'ok', expires_in: 1.second)
    Rails.cache.read('health_check') == 'ok'
  rescue StandardError
    false
  end
end