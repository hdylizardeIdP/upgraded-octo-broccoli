# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.production?
      # In production, use specific allowed origins from environment variable
      origins ENV['ALLOWED_ORIGINS']&.split(',') || []

      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: true,
        expose: ['Authorization']
    else
      # In development/test, allow localhost origins
      origins 'http://localhost:3001', 'http://localhost:3000', /\Ahttp:\/\/localhost:\d+\z/

      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: false,
        expose: ['Authorization']
    end
  end
end
