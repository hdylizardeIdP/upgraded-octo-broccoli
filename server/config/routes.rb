# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'
      post 'auth/logout', to: 'auth#logout'
      post 'auth/refresh', to: 'auth#refresh'
      get 'auth/me', to: 'auth#me'

      # Foods
      resources :foods do
        collection do
          get 'search'
          get 'barcode/:barcode', to: 'foods#barcode'
        end
      end

      # Meals
      resources :meals do
        collection do
          get 'today'
          get 'stats'
        end
      end

      # Users (profile management)
      resources :users, only: [:show, :update, :destroy]

      # Water intake
      resources :water_intakes do
        collection do
          get 'today'
        end
      end

      # Weight tracking
      resources :weights do
        collection do
          get 'latest'
          get 'stats'
        end
      end
    end
  end

  # Health check
  get 'health', to: 'health#index'
end
