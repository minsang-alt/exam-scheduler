module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_reservation, only: [:show, :update, :destroy]
      before_action :authorize_customer, only: [:index, :create]

      def index
        @reservations = if current_admin
          Reservation.includes(:exam_schedule).all # 관리자는 모든 예약 조회, N+1 방지 위해 includes 사용
        else
          current_customer.reservations.includes(:exam_schedule) # 고객은 자신의 예약만 조회, N+1 방지 위해 includes 사용
        end
        
        render json: {
          reservations: @reservations.map { |reservation|
            {
              id: reservation.id,
              exam_schedule: {
                id: reservation.exam_schedule.id,
                start_time: reservation.exam_schedule.start_time,
                end_time: reservation.exam_schedule.end_time
              },
              number_of_people: reservation.number_of_people,
              status: reservation.status,
              created_at: reservation.created_at
            }
          }
        }
      end

      def show
        render json: {
          id: @reservation.id,
          exam_schedule: {
            id: @reservation.exam_schedule.id,
            start_time: @reservation.exam_schedule.start_time,
            end_time: @reservation.exam_schedule.end_time
          },
          number_of_people: @reservation.number_of_people,
          status: @reservation.status,
          created_at: @reservation.created_at
        }
      end

      def create
        ActiveRecord::Base.transaction do
          exam_schedule = ExamSchedule.lock.find(params[:exam_schedule_id])
          
          unless exam_schedule.can_reserve?(params[:number_of_people])
            return render json: { 
              error: '예약 가능한 인원을 초과했습니다.' 
            }, status: :unprocessable_entity
          end

          @reservation = current_customer.reservations.build(
            exam_schedule: exam_schedule,
            number_of_people: params[:number_of_people]
          )
          
          if @reservation.save
            render json: {
              id: @reservation.id,
              exam_schedule: {
                id: exam_schedule.id,
                start_time: exam_schedule.start_time,
                end_time: exam_schedule.end_time
              },
              number_of_people: @reservation.number_of_people,
              status: @reservation.status,
              created_at: @reservation.created_at
            }, status: :created
          else
            render json: { errors: @reservation.errors }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::StaleObjectError
        render json: { error: '다른 사용자가 예약을 진행 중입니다. 다시 시도해주세요.' }, status: :conflict
      end

      private

      def set_reservation
        @reservation = if current_admin
          Reservation.find(params[:id])
        else
          current_customer.reservations.find(params[:id])
        end
      end

      def authorize_customer
        return if current_customer
        render json: { error: '권한이 없습니다.' }, status: :forbidden
      end
    end
  end
end 