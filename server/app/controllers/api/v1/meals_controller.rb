module Api
  module V1
    class MealsController < ApplicationController
      before_action :set_meal, only: [:show, :update, :destroy]

      # GET /api/v1/meals
      # Get all meals for current user
      def index
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 7.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

        meals = current_user.meals
                           .includes(meal_entries: :food)
                           .where(date: start_date..end_date)

        # Filter by meal type if provided
        meals = meals.where(meal_type: params[:meal_type]) if params[:meal_type].present?

        # Order by most recent first
        meals = meals.order(date: :desc, created_at: :desc)

        # Paginate results
        meals = meals.page(params[:page] || 1).per(params[:per_page] || 30)

        render json: {
          meals: meals.map { |m| MealSerializer.new(m).attributes },
          meta: pagination_meta(meals)
        }, status: :ok
      end

      # GET /api/v1/meals/today
      # Get all meals for today
      def today
        meals = current_user.meals
                           .includes(meal_entries: :food)
                           .where(date: Date.today)
                           .order(
                             Arel.sql(
                               "CASE meal_type
                                WHEN 'breakfast' THEN 1
                                WHEN 'lunch' THEN 2
                                WHEN 'dinner' THEN 3
                                WHEN 'snack' THEN 4
                                END"
                             ),
                             created_at: :asc
                           )

        # Calculate total nutrition for the day
        total_nutrition = {
          'calories' => 0,
          'proteinG' => 0,
          'carbsG' => 0,
          'fatG' => 0,
          'fiberG' => 0,
          'sugarG' => 0
        }

        meals.each do |meal|
          meal_nutrition = meal.total_nutrition
          total_nutrition.keys.each do |nutrient|
            total_nutrition[nutrient] += (meal_nutrition[nutrient] || 0)
          end
        end

        render json: {
          meals: meals.map { |m| MealSerializer.new(m).attributes },
          totalNutrition: total_nutrition.transform_values { |v| v.round(2) },
          date: Date.today
        }, status: :ok
      end

      # GET /api/v1/meals/:id
      # Get a specific meal with all entries
      def show
        render json: {
          meal: MealSerializer.new(@meal).attributes
        }, status: :ok
      end

      # POST /api/v1/meals
      # Create a new meal with entries
      def create
        meal = current_user.meals.build(meal_params)

        if meal.save
          render json: {
            meal: MealSerializer.new(meal).attributes,
            message: 'Meal logged successfully'
          }, status: :created
        else
          render json: {
            message: 'Failed to create meal',
            errors: meal.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/meals/:id
      # Update a meal and its entries
      def update
        if @meal.update(meal_params)
          render json: {
            meal: MealSerializer.new(@meal).attributes,
            message: 'Meal updated successfully'
          }, status: :ok
        else
          render json: {
            message: 'Update failed',
            errors: @meal.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/meals/:id
      # Delete a meal (and all associated entries)
      def destroy
        @meal.destroy
        render json: {
          message: 'Meal deleted successfully'
        }, status: :ok
      end

      # GET /api/v1/meals/stats
      # Get meal statistics for a date range
      def stats
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 7.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

        meals = current_user.meals
                           .includes(meal_entries: :food)
                           .where(date: start_date..end_date)

        # Calculate daily averages
        total_days = (end_date - start_date).to_i + 1

        total_nutrition = {
          'calories' => 0,
          'proteinG' => 0,
          'carbsG' => 0,
          'fatG' => 0
        }

        meals.each do |meal|
          meal_nutrition = meal.total_nutrition
          total_nutrition.keys.each do |nutrient|
            total_nutrition[nutrient] += (meal_nutrition[nutrient] || 0)
          end
        end

        daily_averages = total_nutrition.transform_values { |v| (v / total_days).round(2) }

        # Count meals by type
        meals_by_type = meals.group(:meal_type).count

        render json: {
          stats: {
            dateRange: {
              start: start_date,
              end: end_date,
              days: total_days
            },
            totalMeals: meals.count,
            mealsByType: meals_by_type,
            totalNutrition: total_nutrition.transform_values { |v| v.round(2) },
            dailyAverages: daily_averages
          }
        }, status: :ok
      end

      private

      def set_meal
        @meal = current_user.meals.includes(meal_entries: :food).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Meal not found' }, status: :not_found
      end

      def meal_params
        params.require(:meal).permit(
          :date, :meal_type, :name, :notes, :image_url,
          meal_entries_attributes: [:id, :food_id, :servings, :_destroy]
        )
      end

      def pagination_meta(collection)
        {
          currentPage: collection.current_page,
          totalPages: collection.total_pages,
          totalCount: collection.total_count,
          perPage: collection.limit_value
        }
      end
    end
  end
end
