module LocaleHelper
  def available_locales
    [
      { code: 'en', name: 'English', flag: '🇺🇸' },
      { code: 'pt-BR', name: 'Português', flag: '🇧🇷' }
    ]
  end
  
  def current_locale_name
    case I18n.locale.to_s
    when 'en'
      'English'
    when 'pt-BR'
      'Português'
    else
      'English'
    end
  end
  
  def current_locale_flag
    case I18n.locale.to_s
    when 'en'
      '🇺🇸'
    when 'pt-BR'
      '🇧🇷'
    else
      '🇺🇸'
    end
  end
  
  def locale_switch_url(locale_code)
    # Get current URL and replace or add locale parameter
    # Only permit known params to avoid mass assignment vulnerability
    allowed_params = [:controller, :action, :id, :locale, :invitation_token, :wishlist_id, :user_id]
    current_params = params.permit(*allowed_params).to_h
    current_params[:locale] = locale_code
    url_for(current_params)
  end
end