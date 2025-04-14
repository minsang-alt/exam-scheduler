module Api
  module V1
    class ExamSchedulesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_exam_schedule, only: [:show]

      def index
        @exam_schedules = ExamSchedule.available_schedules
        
        render json: {
          schedules: @exam_schedules.map { |schedule| 
            {
              id: schedule.id,
              start_time: schedule.start_time,
              end_time: schedule.end_time,
              max_capacity: schedule.max_capacity,
              current_reservations: schedule.current_reservations,
              available_capacity: schedule.available_capacity,
              is_available: schedule.is_available
            }
          }
        }
      end

      def show
        render json: {
          id: @exam_schedule.id,
          start_time: @exam_schedule.start_time,
          end_time: @exam_schedule.end_time,
          max_capacity: @exam_schedule.max_capacity,
          current_reservations: @exam_schedule.current_reservations,
          available_capacity: @exam_schedule.available_capacity,
          is_available: @exam_schedule.is_available
        }
      end

      private

      def set_exam_schedule
        @exam_schedule = ExamSchedule.find(params[:id])
      end

      def authenticate_user!
        return if current_admin || current_customer
        render json: { error: '인증이 필요합니다.' }, status: :unauthorized
      end
    end
  end
end 