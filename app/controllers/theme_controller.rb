class ThemeController < ApplicationController
  def update
    theme_preference = params[:theme_preference]
    
    if theme_preference.in?(['light', 'dark', 'system'])
      if user_signed_in?
        current_user.update(theme_preference: theme_preference)
      else
        session[:theme_preference] = theme_preference
      end
      
      render json: { success: true, theme: theme_preference }
    else
      render json: { success: false, error: 'Invalid theme preference' }, status: 400
    end
  end
end
