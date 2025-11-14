module Api
  module V1
    class FoodsController < ApplicationController
      before_action :set_food, only: [:show, :update, :destroy]
      before_action :authorize_food, only: [:update, :destroy]

      # GET /api/v1/foods
      # Get all foods (USDA + custom foods for current user)
      def index
        # Show USDA foods (is_custom = false) and user's custom foods
        foods = Food.where('is_custom = ? OR (is_custom = ? AND user_id = ?)',
                          false, true, current_user.id)

        # Apply filters
        foods = foods.where(is_custom: params[:custom_only]) if params[:custom_only].present?

        # Order by most recently created first
        foods = foods.order(created_at: :desc)

        # Paginate results
        foods = foods.page(params[:page] || 1).per(params[:per_page] || 50)

        render json: {
          foods: foods.map { |f| FoodSerializer.new(f).attributes },
          meta: pagination_meta(foods)
        }, status: :ok
      end

      # GET /api/v1/foods/search?q=chicken
      # Search for foods by name or brand
      def search
        query = params[:q]

        if query.blank?
          return render json: {
            message: 'Search query is required'
          }, status: :bad_request
        end

        # Search USDA foods and user's custom foods
        foods = Food.search(query)
                   .where('is_custom = ? OR (is_custom = ? AND user_id = ?)',
                         false, true, current_user.id)
                   .limit(params[:limit] || 20)

        render json: {
          foods: foods.map { |f| FoodSerializer.new(f).attributes },
          query: query,
          count: foods.size
        }, status: :ok
      end

      # GET /api/v1/foods/barcode/:barcode
      # Look up food by barcode
      def barcode
        barcode_value = params[:barcode]

        if barcode_value.blank?
          return render json: {
            message: 'Barcode is required'
          }, status: :bad_request
        end

        food = Food.find_by(barcode: barcode_value)

        if food
          render json: {
            food: FoodSerializer.new(food).attributes
          }, status: :ok
        else
          render json: {
            message: 'Food not found for this barcode',
            barcode: barcode_value
          }, status: :not_found
        end
      end

      # GET /api/v1/foods/:id
      # Get a specific food
      def show
        render json: {
          food: FoodSerializer.new(@food).attributes
        }, status: :ok
      end

      # POST /api/v1/foods
      # Create a custom food
      def create
        food = current_user.foods.build(food_params)
        food.is_custom = true

        if food.save
          render json: {
            food: FoodSerializer.new(food).attributes,
            message: 'Custom food created successfully'
          }, status: :created
        else
          render json: {
            message: 'Failed to create food',
            errors: food.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/foods/:id
      # Update a custom food (only owner can update)
      def update
        if @food.update(food_params)
          render json: {
            food: FoodSerializer.new(@food).attributes,
            message: 'Food updated successfully'
          }, status: :ok
        else
          render json: {
            message: 'Update failed',
            errors: @food.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/foods/:id
      # Delete a custom food (only owner can delete)
      def destroy
        @food.destroy
        render json: {
          message: 'Food deleted successfully'
        }, status: :ok
      end

      private

      def set_food
        @food = Food.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Food not found' }, status: :not_found
      end

      def authorize_food
        # Only allow modification of custom foods that belong to the current user
        unless @food.is_custom && @food.user_id == current_user.id
          render json: {
            error: 'Unauthorized - you can only modify your own custom foods'
          }, status: :forbidden
        end
      end

      def food_params
        params.require(:food).permit(
          :name, :brand, :serving_size, :serving_unit,
          :barcode, :usda_id,
          nutrition: [
            :calories, :proteinG, :carbsG, :fatG, :fiberG, :sugarG,
            :saturatedFatG, :transFatG, :cholesterolMg, :sodiumMg,
            :potassiumMg, :vitaminAMcg, :vitaminCMg, :calciumMg, :ironMg
          ]
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
