# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :auth, :api_key, :access_token, :refresh_token, :jwt, :bearer,
  :name, :phone, :mobile, :address, :street, :city, :postal_code, :zip,
  :card, :account, :routing, :bank,
  :session, :cookie, :csrf,
  :latitude, :longitude, :ip_address,
  :birth, :dob, :age,
  :answer, :question # security questions
]

# Also filter headers that might contain sensitive data
Rails.application.config.filter_redirect = ['https://'] # Don't log redirect URLs with sensitive params
