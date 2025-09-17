module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_locale

    def connect
      self.current_user = find_verified_user
      self.current_locale = find_locale
    end

    private

    def find_verified_user
      if verified_user = env['warden'].user
        verified_user
      else
        reject_unauthorized_connection
      end
    end

    def find_locale
      # Locale will be set from the subscription parameters
      # Default to English for now, will be updated when channels subscribe
      Rails.logger.info "ActionCable Connection - Using default locale: #{I18n.default_locale}"
      I18n.default_locale
    end
  end
end
