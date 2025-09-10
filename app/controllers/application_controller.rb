class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :store_user_location!, if: :storable_location?

  private

  def set_locale
    I18n.locale = params[:locale] ||
                  current_user&.preferred_locale ||
                  extract_locale_from_accept_language_header ||
                  I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    accepted_languages = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/)
    return "pt-BR" if accepted_languages.include?("pt")
    return "en" if accepted_languages.include?("en")
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
end
