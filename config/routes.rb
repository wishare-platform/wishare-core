Rails.application.routes.draw do
  patch '/theme', to: 'theme#update'
  patch '/locale', to: 'locale#update'

  # Root route without locale - redirect to appropriate localized version
  get '/', to: 'root_redirect#index'


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
    post '/address_lookups/lookup', to: 'address_lookups#lookup'
    
    # Public user profiles
    resources :users, only: [:show]

    # Profile management
    resource :profile, only: [:show, :edit, :update] do
      patch :update_avatar
      delete :remove_avatar
    end
    
    # Notification preferences
    resource :notification_preferences, only: [:show, :update]
    
    # API routes for mobile app
    namespace :api do
      namespace :v1 do
        # Authentication
        post 'auth/login', to: 'auth#login'
        delete 'auth/logout', to: 'auth#logout'
        post 'auth/refresh', to: 'auth#refresh_token'
        get 'auth/validate', to: 'auth#validate_token'

        # Resources
        resources :wishlists do
          resources :wishlist_items, path: 'items' do
            member do
              patch :toggle_purchase
            end
          end
        end

        # Device tokens for push notifications
        resources :device_tokens do
          collection do
            post :test_notification
          end
        end

        # User profile
        get 'user/profile', to: 'users#profile'
        patch 'user/profile', to: 'users#update_profile'
        patch 'user/avatar', to: 'users#update_avatar'
        resources :users, only: [:show]

        # Notifications
        resources :notifications do
          member do
            patch :mark_as_read
          end
          collection do
            patch :mark_all_as_read
            get :unread_count
          end
        end

        # Connections
        resources :connections do
          member do
            patch :update
          end
          collection do
            get :friends
          end
        end

        # Invitations
        resources :invitations do
          member do
            patch :update
          end
        end
        # Invitation by token (public endpoint)
        get 'invitations/token/:token', to: 'invitations#show', as: :invitation_by_token
        patch 'invitations/token/:token', to: 'invitations#update', as: :update_invitation_by_token

        # Mobile-specific endpoints
        get 'mobile/health', to: 'mobile#health_check'
        get 'mobile/config', to: 'mobile#config'
        get 'mobile/feature-flags', to: 'mobile#feature_flags'
        post 'mobile/device-info', to: 'mobile#device_info'
        get 'mobile/sync', to: 'mobile#sync_data'
        post 'mobile/track-event', to: 'mobile#track_event'
        post 'mobile/test-push', to: 'mobile#test_push_notification'

        # Image upload for mobile
        post 'wishlists/:wishlist_id/items/:item_id/image', to: 'mobile#upload_image'
        post 'profile/avatar', to: 'mobile#upload_avatar'
        post 'wishlists/:wishlist_id/cover-image', to: 'mobile#upload_wishlist_cover'
      end
    end
    
    # Admin routes
    namespace :admin do
      root 'dashboard#index'
      resources :users, only: [:index, :show, :update, :destroy]
      resources :wishlists, only: [:index, :show, :destroy]
    end
    
    authenticated :user do
      root 'dashboard#index', as: :authenticated_root
    end
    
    root 'landing#index'

    # Use case pages
    get '/for/birthdays', to: 'use_cases#birthdays', as: :use_case_birthdays
    get '/for/weddings', to: 'use_cases#weddings', as: :use_case_weddings
    get '/for/holidays', to: 'use_cases#holidays', as: :use_case_holidays
    get '/for/couples', to: 'use_cases#couples', as: :use_case_couples
    get '/for/families', to: 'use_cases#families', as: :use_case_families

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

  # Catch-all route for 404 errors (must be last)
  # Exclude Rails internal paths (ActiveStorage, etc.)
  match '*path', to: 'application#handle_404', via: :all,
        constraints: ->(request) {
          !request.path.start_with?('/rails/')
        }
end
