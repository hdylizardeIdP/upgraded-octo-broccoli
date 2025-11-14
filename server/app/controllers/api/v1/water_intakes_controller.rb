module Api
  module V1
    class WaterIntakesController < ApplicationController
      before_action :set_water_intake, only: [:show, :update, :destroy]

      # GET /api/v1/water_intakes
      # Get all water intake records for current user
      def index
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

        water_intakes = current_user.water_intakes
                                   .where(date: start_date..end_date)
                                   .order(date: :desc)

        # Paginate results
        water_intakes = water_intakes.page(params[:page] || 1).per(params[:per_page] || 30)

        render json: {
          waterIntakes: water_intakes.map { |wi| WaterIntakeSerializer.new(wi).attributes },
          meta: pagination_meta(water_intakes)
        }, status: :ok
      end

      # GET /api/v1/water_intakes/today
      # Get today's total water intake
      def today
        total = current_user.water_intakes.for_date(Date.today).sum(:amount_ml)

        render json: {
          date: Date.today,
          totalMl: total,
          totalOz: (total / 29.5735).round(2),
          totalCups: (total / 236.588).round(2)
        }, status: :ok
      end

      # GET /api/v1/water_intakes/:id
      # Get a specific water intake record
      def show
        render json: {
          waterIntake: WaterIntakeSerializer.new(@water_intake).attributes
        }, status: :ok
      end

      # POST /api/v1/water_intakes
      # Create a new water intake record
      def create
        water_intake = current_user.water_intakes.build(water_intake_params)

        if water_intake.save
          render json: {
            waterIntake: WaterIntakeSerializer.new(water_intake).attributes,
            message: 'Water intake logged successfully'
          }, status: :created
        else
          render json: {
            message: 'Failed to log water intake',
            errors: water_intake.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/water_intakes/:id
      # Update a water intake record
      def update
        if @water_intake.update(water_intake_params)
          render json: {
            waterIntake: WaterIntakeSerializer.new(@water_intake).attributes,
            message: 'Water intake updated successfully'
          }, status: :ok
        else
          render json: {
            message: 'Update failed',
            errors: @water_intake.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/water_intakes/:id
      # Delete a water intake record
      def destroy
        @water_intake.destroy
        render json: {
          message: 'Water intake record deleted successfully'
        }, status: :ok
      end

      private

      def set_water_intake
        @water_intake = current_user.water_intakes.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Water intake record not found' }, status: :not_found
      end

      def water_intake_params
        params.require(:water_intake).permit(:date, :amount_ml)
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
