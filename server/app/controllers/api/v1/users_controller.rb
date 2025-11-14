module Api
  module V1
    class UsersController < ApplicationController
      before_action :set_user, only: [:show, :update, :destroy]
      before_action :authorize_user, only: [:update, :destroy]

      # GET /api/v1/users/:id
      # Get user profile (only own profile)
      def show
        render json: {
          user: UserSerializer.new(@user).attributes
        }, status: :ok
      end

      # PATCH/PUT /api/v1/users/:id
      # Update user profile
      def update
        if @user.update(user_params)
          render json: {
            user: UserSerializer.new(@user).attributes,
            message: 'Profile updated successfully'
          }, status: :ok
        else
          render json: {
            message: 'Update failed',
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id
      # Delete user account
      def destroy
        @user.destroy
        render json: {
          message: 'Account deleted successfully'
        }, status: :ok
      end

      private

      def set_user
        @user = User.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :not_found
      end

      def authorize_user
        unless current_user.id == @user.id
          render json: { error: 'Unauthorized' }, status: :forbidden
        end
      end

      def user_params
        params.require(:user).permit(
          :email, :password, :password_confirmation, :name,
          :date_of_birth, :gender, :height_cm, :weight_kg,
          :activity_level, goals: {}
        )
      end
    end
  end
end
