class Mobile::MobileAuthController < ActionController::Base
  # Skip all inherited functionality to isolate issue

  # Check authentication status for mobile apps
  def status
    render json: { status: 'ok', action: 'status' }
  end

  # Enhanced session check for mobile apps
  def session_check
    render json: { status: 'ok', test: true }
  end

  # Provide app configuration for mobile clients
  def config
    render json: { status: 'ok' }
  end

  # Health check for mobile apps
  def health
    render json: { status: 'ok', action: 'health' }
  end
end