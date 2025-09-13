# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from Hotwire Native apps (localhost for development)
    origins 'http://localhost:3000',
            'http://localhost:3001',
            'capacitor://localhost',
            'ionic://localhost',
            'http://localhost',
            'http://localhost:8080',
            'http://localhost:8100'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
  end

  # Production configuration
  allow do
    origins 'https://wishare.xyz',
            'https://www.wishare.xyz',
            'capacitor://wishare.xyz',
            'wishare://'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
  end
end