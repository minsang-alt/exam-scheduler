module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_reservation, only: [ :show, :update, :destroy, :confirm, :cancel ]
      before_action :authorize_customer, only: [ :create ]
      before_action :authorize_modification, only: [ :update, :destroy ]
      before_action :authorize_admin, only: [ :confirm ]

      def index
        @reservations = if current_admin
          Reservation.includes(:exam_schedule).all
        else
          current_customer.reservations.includes(:exam_schedule)
        end

        render json: { reservations: @reservations.map { |reservation| reservation_json(reservation) } }
      end

      def show
        render json: reservation_json(@reservation)
      end

      def create
        ActiveRecord::Base.transaction do
          exam_schedule = ExamSchedule.lock("FOR UPDATE").find(params[:exam_schedule_id])

          unless exam_schedule.can_reserve?(params[:number_of_people])
            return render_error("예약 가능한 인원을 초과했습니다.", :unprocessable_entity)
          end

          @reservation = current_customer.reservations.build(
            exam_schedule: exam_schedule,
            number_of_people: params[:number_of_people]
          )

          if @reservation.save
            render json: reservation_json(@reservation), status: :created
          else
            render json: { errors: @reservation.errors }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::LockWaitTimeout
        render_lock_error("다른 사용자가 예약을 진행 중입니다. 나중에 다시 시도해주세요.")
      end

      def update
        ActiveRecord::Base.transaction do
          with_locked_resources(@reservation) do |reservation, exam_schedule|
            return render_error("확정된 예약은 수정할 수 없습니다.", :unprocessable_entity) unless reservation.pending?

            if needs_capacity_check?
              return render_error("예약 가능한 인원을 초과했습니다.", :unprocessable_entity) unless exam_schedule.can_reserve?(params[:number_of_people].to_i)
            end

            if reservation.update(reservation_params)
              render json: reservation_json(reservation)
            else
              render json: { errors: reservation.errors }, status: :unprocessable_entity
            end
          end
        end
      rescue ActiveRecord::LockWaitTimeout
        render_lock_error("다른 사용자가 예약을 수정 중입니다. 나중에 다시 시도해주세요.")
      end

      def destroy
        if @reservation.destroy
          head :no_content
        else
          render_error("예약 삭제에 실패했습니다.", :unprocessable_entity)
        end
      end

      def confirm
        ActiveRecord::Base.transaction do
          with_locked_resources(@reservation) do |reservation, exam_schedule|
            if reservation.pending? && exam_schedule.can_reserve?(reservation.number_of_people)
              reservation.update!(status: "confirmed")
              exam_schedule.increment!(:current_reservations, reservation.number_of_people)

              render json: {
                id: reservation.id,
                status: reservation.status,
                message: "예약이 확정되었습니다."
              }
            else
              render_error("예약 확정에 실패했습니다. 가용 인원을 확인해주세요.", :unprocessable_entity)
            end
          end
        end
      rescue ActiveRecord::LockWaitTimeout
        render_lock_error("다른 관리자가 이 예약을 처리 중입니다. 나중에 다시 시도해주세요.")
      end

      def cancel
        ActiveRecord::Base.transaction do
          with_locked_resources(@reservation) do |reservation, exam_schedule|
            return render_error("이미 취소된 예약입니다.", :unprocessable_entity) if reservation.cancelled?

            was_confirmed = reservation.confirmed?

            reservation.update!(status: "cancelled")

            if was_confirmed
              exam_schedule.decrement!(:current_reservations, reservation.number_of_people)
            end

            render json: {
              id: reservation.id,
              status: reservation.status,
              message: "예약이 취소되었습니다."
            }
          end
        end
      rescue ActiveRecord::LockWaitTimeout
        render_lock_error("다른 사용자가 이 예약을 처리 중입니다. 나중에 다시 시도해주세요.")
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
        render_error("권한이 없습니다.", :forbidden)
      end

      def authorize_admin
        return if current_admin
        render_error("관리자 권한이 필요합니다.", :forbidden)
      end

      def authorize_modification
        return if @reservation.can_be_modified_by?(current_admin || current_customer)
        render_error("이 예약을 수정/삭제할 권한이 없습니다.", :forbidden)
      end

      def reservation_params
        params.permit(:number_of_people)
      end

      def with_locked_resources(reservation)
        reservation.lock!
        exam_schedule = reservation.exam_schedule.lock!
        yield(reservation, exam_schedule)
      end

      def needs_capacity_check?
        params[:number_of_people].present? && params[:number_of_people].to_i != @reservation.number_of_people
      end

      def reservation_json(reservation)
        {
          id: reservation.id,
          exam_schedule: {
            id: reservation.exam_schedule.id,
            start_time: reservation.exam_schedule.start_time,
            end_time: reservation.exam_schedule.end_time
          },
          number_of_people: reservation.number_of_people,
          status: reservation.status,
          created_at: reservation.created_at,
          updated_at: reservation.updated_at
        }
      end

      def render_error(message, status)
        render json: { error: message }, status: status
      end

      def render_lock_error(message)
        render_error(message, :conflict)
      end
    end
  end
end
