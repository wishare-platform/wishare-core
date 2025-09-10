# Configure SendGrid API delivery method for ActionMailer
# This uses SendGrid's HTTPS API instead of SMTP (which is blocked on Railway free tier)

# Only initialize delivery method when not in asset precompilation mode
unless ENV['SECRET_KEY_BASE_DUMMY'] == '1' || defined?(Rails::Assets) && Rails.env.production?
  require_relative '../../lib/sendgrid_api_delivery'
  ActionMailer::Base.add_delivery_method :sendgrid_api, SendgridApiDelivery
end