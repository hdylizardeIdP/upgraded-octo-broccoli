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
        end
        member do
          get 'barcode/:barcode', to: 'foods#barcode', on: :collection
        end
      end

      # Meals
      resources :meals

      # Nutrition summaries
      get 'nutrition/daily', to: 'nutrition#daily'
      get 'nutrition/weekly', to: 'nutrition#weekly'

      # User profile and goals
      get 'users/profile', to: 'users#profile'
      put 'users/profile', to: 'users#update_profile'
      put 'users/goals', to: 'users#update_goals'

      # Water intake
      resources :water_intakes, only: [:index, :create, :destroy]

      # Weight tracking
      resources :weights, only: [:index, :create, :update, :destroy]
    end
  end

  # Health check
  get 'health', to: 'health#index'
end
