# Configure SendGrid API delivery method for ActionMailer
# This uses SendGrid's HTTPS API instead of SMTP (which is blocked on Railway free tier)

# Add sendgrid_api_settings accessor to ActionMailer::Base
ActionMailer::Base.class_eval do
  # Only add the accessor if it doesn't already exist
  unless respond_to?(:sendgrid_api_settings)
    cattr_accessor :sendgrid_api_settings
  end
end

# Only initialize delivery method when not in asset precompilation mode
unless ENV['SECRET_KEY_BASE_DUMMY'] == '1' || defined?(Rails::Assets) && Rails.env.production?
  require_relative '../../lib/sendgrid_api_delivery'
  ActionMailer::Base.add_delivery_method :sendgrid_api, SendgridApiDelivery
end