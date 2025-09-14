class LocaleController < ApplicationController
  def update
    new_locale = params[:locale]

    # Validate the locale
    if ['en', 'pt-BR'].include?(new_locale)
      # Update user preference if logged in
      if current_user
        current_user.update(preferred_locale: new_locale)
      end

      # Set the session locale
      session[:locale] = new_locale

      # Respond based on request type
      respond_to do |format|
        format.json { render json: { success: true, locale: new_locale } }
        format.html { redirect_back(fallback_location: root_path) }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: 'Invalid locale' }, status: :unprocessable_entity }
        format.html { redirect_back(fallback_location: root_path, alert: 'Invalid language selection') }
      end
    end
  end
end