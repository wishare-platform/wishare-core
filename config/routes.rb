Rails.application.routes.draw do
  # Make sure this is BEFORE other routes
  root "home#index"

  devise_for :users
  
  resources :wishlists do
    resources :items, only: [:create, :destroy]
  end

  resources :couples do
    resources :wishlists, controller: 'couple_wishlists'
    member do
      post :invite
      patch :accept
      delete :decline
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end