Rails.application.routes.draw do
  # OAuth callbacks must be outside of locale scope
  devise_for :users, only: :omniauth_callbacks, controllers: { 
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  
  # Locale scope for internationalization
  scope "(:locale)", locale: /en|pt-BR/ do
    devise_for :users, skip: :omniauth_callbacks, controllers: { 
      registrations: 'users/registrations'
    }
    
    # Resources for authenticated users
    resources :connections, only: [:index, :show, :update, :destroy]
    resources :invitations, only: [:new, :create, :destroy]
    resources :notifications, only: [:index] do
      member do
        patch :mark_as_read
      end
      collection do
        patch :mark_all_as_read
      end
    end
    get '/invite/:token', to: 'invitations#show', as: :accept_invitation
    patch '/invite/:token', to: 'invitations#update', as: :update_invitation
    resources :wishlists do
      resources :wishlist_items, path: 'items' do
        member do
          patch :purchase
          patch :unpurchase
        end
      end
    end
    
    # Utility endpoints
    post '/wishlist_items/extract_url_metadata', to: 'wishlist_items#extract_url_metadata'
    
    # Public user profiles
    resources :users, only: [:show]
    
    # Notification preferences
    resource :notification_preferences, only: [:show, :update]
    
    # API routes for mobile app
    namespace :api do
      namespace :v1 do
        resources :device_tokens, only: [:create, :index, :destroy]
      end
    end
    
    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end
    
    root 'landing#index'
    
    # Cookie consent management
    get '/cookie-preferences', to: 'cookie_consents#show', as: :cookie_consent
    post '/cookie-consent', to: 'cookie_consents#create', as: :create_cookie_consent
    patch '/cookie-consent', to: 'cookie_consents#update', as: :update_cookie_consent
    
    # Legal pages
    get '/terms-of-service', to: 'legal#terms_of_service', as: :terms_of_service
    get '/privacy-policy', to: 'legal#privacy_policy', as: :privacy_policy
    
    # Debug routes (development only)
    if Rails.env.development?
      get '/debug/analytics-status', to: 'debug#analytics_status', as: :debug_analytics_status
      post '/debug/toggle-consent', to: 'debug#toggle_consent', as: :debug_toggle_consent
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
