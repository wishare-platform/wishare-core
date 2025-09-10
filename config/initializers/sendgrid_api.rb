# Configure SendGrid API delivery method for ActionMailer
# This uses SendGrid's HTTPS API instead of SMTP (which is blocked on Railway free tier)
require_relative '../../lib/sendgrid_api_delivery'

ActionMailer::Base.add_delivery_method :sendgrid_api, SendgridApiDelivery