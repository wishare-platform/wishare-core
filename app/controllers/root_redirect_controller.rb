class RootRedirectController < ApplicationController
  def index
    # If user is authenticated, redirect directly to dashboard
    if user_signed_in?
      redirect_to '/dashboard', status: :moved_permanently
      return
    end

    # Determine the appropriate locale for non-authenticated users
    locale = params[:locale] ||
             session[:locale] ||
             extract_locale_from_accept_language_header ||
             I18n.default_locale

    # Redirect to localized root path
    # The routes.rb will handle non-authenticated routing
    redirect_to "/#{locale}", status: :moved_permanently
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