module Api
  module V1
    class WeightsController < ApplicationController
      before_action :set_weight, only: [:show, :update, :destroy]

      # GET /api/v1/weights
      # Get all weight records for current user
      def index
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 90.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

        weights = current_user.weights
                             .where(date: start_date..end_date)
                             .order(date: :desc)

        # Paginate results
        weights = weights.page(params[:page] || 1).per(params[:per_page] || 30)

        render json: {
          weights: weights.map { |w| WeightSerializer.new(w).attributes },
          meta: pagination_meta(weights)
        }, status: :ok
      end

      # GET /api/v1/weights/latest
      # Get the most recent weight record
      def latest
        weight = current_user.weights.order(date: :desc).first

        if weight
          render json: {
            weight: WeightSerializer.new(weight).attributes
          }, status: :ok
        else
          render json: {
            message: 'No weight records found'
          }, status: :not_found
        end
      end

      # GET /api/v1/weights/stats
      # Get weight statistics (trends, averages, etc.)
      def stats
        weights = current_user.weights.order(date: :asc)

        if weights.empty?
          return render json: {
            message: 'No weight records found'
          }, status: :not_found
        end

        first_weight = weights.first
        latest_weight = weights.last
        total_change = latest_weight.weight_kg - first_weight.weight_kg

        # Calculate 7-day and 30-day averages
        weights_7d = current_user.weights.where('date >= ?', 7.days.ago).average(:weight_kg)
        weights_30d = current_user.weights.where('date >= ?', 30.days.ago).average(:weight_kg)

        render json: {
          stats: {
            currentWeight: latest_weight.weight_kg,
            startingWeight: first_weight.weight_kg,
            totalChange: total_change.round(2),
            average7Days: weights_7d&.round(2),
            average30Days: weights_30d&.round(2),
            highestWeight: weights.maximum(:weight_kg),
            lowestWeight: weights.minimum(:weight_kg),
            totalRecords: weights.count,
            dateRange: {
              start: first_weight.date,
              end: latest_weight.date
            }
          }
        }, status: :ok
      end

      # GET /api/v1/weights/:id
      # Get a specific weight record
      def show
        render json: {
          weight: WeightSerializer.new(@weight).attributes
        }, status: :ok
      end

      # POST /api/v1/weights
      # Create a new weight record
      def create
        weight = current_user.weights.build(weight_params)

        if weight.save
          render json: {
            weight: WeightSerializer.new(weight).attributes,
            message: 'Weight logged successfully'
          }, status: :created
        else
          render json: {
            message: 'Failed to log weight',
            errors: weight.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/weights/:id
      # Update a weight record
      def update
        if @weight.update(weight_params)
          render json: {
            weight: WeightSerializer.new(@weight).attributes,
            message: 'Weight updated successfully'
          }, status: :ok
        else
          render json: {
            message: 'Update failed',
            errors: @weight.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/weights/:id
      # Delete a weight record
      def destroy
        @weight.destroy
        render json: {
          message: 'Weight record deleted successfully'
        }, status: :ok
      end

      private

      def set_weight
        @weight = current_user.weights.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Weight record not found' }, status: :not_found
      end

      def weight_params
        params.require(:weight).permit(:date, :weight_kg, :notes)
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
