class RootRedirectController < ApplicationController
  def index
    # Determine the appropriate locale
    locale = params[:locale] ||
             session[:locale] ||
             current_user&.preferred_locale ||
             extract_locale_from_accept_language_header ||
             I18n.default_locale

    # Redirect based on authentication status
    if user_signed_in?
      redirect_to "/#{locale}/dashboard", status: :moved_permanently
    else
      redirect_to "/#{locale}", status: :moved_permanently
    end
  end

  private

  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']

    accepted_languages = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/)
    return 'pt-BR' if accepted_languages.include?('pt')
    return 'en' if accepted_languages.include?('en')
    nil
  end
end