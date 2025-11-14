module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: [:register, :login]

      # POST /api/v1/auth/register
      # Create a new user account
      def register
        user = User.new(user_params)

        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            user: UserSerializer.new(user).attributes,
            tokens: {
              accessToken: token,
              refreshToken: token, # TODO: Implement separate refresh token
              expiresIn: 86400 # 24 hours in seconds
            }
          }, status: :created
        else
          render json: {
            message: 'Registration failed',
            errors: user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      # Authenticate user and return JWT token
      def login
        user = User.find_by(email: login_params[:email]&.downcase)

        if user&.authenticate(login_params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            user: UserSerializer.new(user).attributes,
            tokens: {
              accessToken: token,
              refreshToken: token, # TODO: Implement separate refresh token
              expiresIn: 86400 # 24 hours in seconds
            }
          }, status: :ok
        else
          render json: {
            message: 'Invalid email or password'
          }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/logout
      # Logout user (invalidate token)
      def logout
        # TODO: Implement token blacklist with Redis
        # For now, just return success - client will discard token
        render json: {
          message: 'Logged out successfully'
        }, status: :ok
      end

      # POST /api/v1/auth/refresh
      # Refresh JWT token
      def refresh
        # Current user is already authenticated via before_action
        token = JsonWebToken.encode(user_id: current_user.id)
        render json: {
          tokens: {
            accessToken: token,
            refreshToken: token, # TODO: Implement separate refresh token
            expiresIn: 86400 # 24 hours in seconds
          }
        }, status: :ok
      end

      # GET /api/v1/auth/me
      # Get current user profile
      def me
        render json: {
          user: UserSerializer.new(current_user).attributes
        }, status: :ok
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :name, :date_of_birth, :gender, :height_cm, :weight_kg, :activity_level, goals: {})
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end
    end
  end
end
