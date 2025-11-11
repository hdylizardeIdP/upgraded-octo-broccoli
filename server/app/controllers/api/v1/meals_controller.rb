# app/controllers/api/v1/meals_controller.rb
# Example Rails controller implementing the Meals API

module Api
  module V1
    class MealsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_meal, only: [:show, :update, :destroy]

      # GET /api/v1/meals?date=2024-03-15
      def index
        date = params[:date]
        
        if date.blank?
          return render json: { message: 'Date parameter is required' }, status: :bad_request
        end

        meals = current_user.meals
                           .includes(meal_entries: :food)
                           .for_date(date)
                           .order(created_at: :asc)

        render json: meals, 
               each_serializer: MealSerializer,
               include: ['meal_entries', 'meal_entries.food']
      end

      # GET /api/v1/meals/:id
      def show
        render json: @meal,
               serializer: MealSerializer,
               include: ['meal_entries', 'meal_entries.food']
      end

      # POST /api/v1/meals
      def create
        meal = current_user.meals.build(meal_params)

        if meal.save
          create_meal_entries(meal, params[:entries]) if params[:entries].present?
          
          render json: meal,
                 serializer: MealSerializer,
                 include: ['meal_entries', 'meal_entries.food'],
                 status: :created
        else
          render json: { 
            message: 'Failed to create meal',
            details: meal.errors 
          }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/meals/:id
      def update
        if @meal.update(meal_params)
          # Update meal entries if provided
          if params[:entries].present?
            @meal.meal_entries.destroy_all
            create_meal_entries(@meal, params[:entries])
          end

          render json: @meal,
                 serializer: MealSerializer,
                 include: ['meal_entries', 'meal_entries.food']
        else
          render json: { 
            message: 'Failed to update meal',
            details: @meal.errors 
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/meals/:id
      def destroy
        @meal.destroy
        head :no_content
      end

      private

      def set_meal
        @meal = current_user.meals.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { message: 'Meal not found' }, status: :not_found
      end

      def meal_params
        params.require(:meal).permit(:date, :meal_type, :name, :notes, :image_url)
      end

      def create_meal_entries(meal, entries_data)
        entries_data.each do |entry_data|
          meal.meal_entries.create!(
            food_id: entry_data[:foodId],
            servings: entry_data[:servings]
          )
        end
      end
    end
  end
end
