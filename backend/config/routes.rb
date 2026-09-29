Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: :create
      resource :session, only: [ :create, :destroy ]
      resource :me, only: [ :show, :destroy ], controller: "me" do
        get :reviews
      end

      resources :cuisines, only: :index
      resources :dishes, only: [ :index, :show, :create ]
      resources :restaurants, only: [ :index, :show, :create ] do
        resources :reviews, only: :create, controller: "restaurant_reviews"
      end
      resources :restaurant_dishes, only: [ :show, :create ] do
        resources :reviews, only: :index
      end
      resources :reviews, only: [ :update, :destroy ]

      get "geocode", to: "geocoding#search"
      get "geocode/reverse", to: "geocoding#reverse"
    end
  end

  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
