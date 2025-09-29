class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # Temporarily commented out to debug JavaScript issues
  # allow_browser versions: :modern

  before_action :set_locale
  before_action :store_user_location!, if: :storable_location?
  before_action :detect_mobile_app

  # Error handling - catches routing errors and other exceptions
  unless Rails.application.config.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    rescue_from ActionController::RoutingError, with: :render_404
    rescue_from StandardError, with: :render_500
  end

  # Public action for handling 404 routes
  def handle_404
    # Extract locale from path for 404 routes and set it immediately
    if params[:path]&.match(/^(en|pt-BR)\//)
      locale_from_path = params[:path].split('/').first
      if %w[en pt-BR].include?(locale_from_path)
        I18n.locale = locale_from_path
        params[:locale] = locale_from_path
      end
    end

    render_404
  end

  private
  
  def set_locale
    I18n.locale = params[:locale] ||
                  session[:locale] ||
                  current_user&.preferred_locale ||
                  extract_locale_from_accept_language_header ||
                  I18n.default_locale

    # Store locale preference if user is logged in and locale changed
    # Use update_column to avoid callbacks that could cause recursion
    if current_user && params[:locale] && params[:locale] != current_user.preferred_locale
      current_user.update_column(:preferred_locale, params[:locale])
    end
  end
  
  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']
    
    accepted_languages = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/)
    return 'pt-BR' if accepted_languages.include?('pt')
    return 'en' if accepted_languages.include?('en')
    nil
  end
  
  def default_url_options
    { locale: I18n.locale }
  end
  
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def render_404
    respond_to do |format|
      format.html { render template: 'errors/not_found', status: :not_found, layout: false }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end

  def render_500
    respond_to do |format|
      format.html { render file: Rails.public_path.join('500.html'), status: :internal_server_error, layout: false }
      format.json { render json: { error: 'Internal server error' }, status: :internal_server_error }
    end
  end

  def detect_mobile_app
    @is_mobile_app = request.user_agent&.include?('Hotwire Native') ||
                     request.headers['X-Hotwire-Native'].present? ||
                     request.headers['X-Mobile-App'].present?

    Rails.logger.info "Mobile app detected: #{@is_mobile_app}" if @is_mobile_app
  end

  def mobile_app?
    @is_mobile_app
  end

  # Override Devise's after_sign_in_path_for to handle mobile apps
  def after_sign_in_path_for(resource)
    if mobile_app?
      # For mobile apps, always go to dashboard
      global_dashboard_path
    else
      # For web users, use stored location or dashboard
      stored_location_for(resource) || global_dashboard_path
    end
  end

  # Override Devise's after_sign_out_path_for to handle mobile apps
  def after_sign_out_path_for(resource_or_scope)
    if mobile_app?
      # For mobile apps, go to root
      root_path
    else
      # For web users, go to root
      root_path
    end
  end
end
