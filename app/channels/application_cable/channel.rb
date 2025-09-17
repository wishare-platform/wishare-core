module ApplicationCable
  class Channel < ActionCable::Channel::Base
    # Override subscribed to set locale
    def subscribed
      I18n.locale = connection.current_locale
      super
    rescue NotImplementedError
      # If subclass doesn't implement subscribed, that's fine
    end
  end
end
