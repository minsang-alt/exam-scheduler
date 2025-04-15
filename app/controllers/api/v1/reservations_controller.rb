module Api
  module V1
    class ReservationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_reservation, only: [:show, :update, :destroy, :confirm, :cancel]
      before_action :authorize_customer, only: [:index, :create]
      before_action :authorize_modification, only: [:update, :destroy]
      before_action :authorize_admin, only: [:confirm]

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
          # 비관적 락 적용
          exam_schedule = ExamSchedule.lock('FOR UPDATE').find(params[:exam_schedule_id])
          
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
      rescue ActiveRecord::LockWaitTimeout
        render json: { error: '다른 사용자가 예약을 진행 중입니다. 나중에 다시 시도해주세요.' }, status: :conflict
      end

      def update
        ActiveRecord::Base.transaction do
          # 비관적 락 적용: 예약과 관련 시험 일정을 동시에 잠급니다
          @reservation.lock!
          exam_schedule = @reservation.exam_schedule.lock!

          # 예약 상태가 pending일 경우에만 수정 가능
          unless @reservation.status == 'pending'
            return render json: { error: '확정된 예약은 수정할 수 없습니다.' }, status: :unprocessable_entity
          end

          # 수정할 인원 수가 기존과 다르고, 수용 가능한지 확인
          if params[:number_of_people].present? && params[:number_of_people].to_i != @reservation.number_of_people
            unless exam_schedule.can_reserve?(params[:number_of_people].to_i)
              return render json: { error: '예약 가능한 인원을 초과했습니다.' }, status: :unprocessable_entity
            end
          end

          if @reservation.update(reservation_params)
            render json: {
              id: @reservation.id,
              exam_schedule: {
                id: exam_schedule.id,
                start_time: exam_schedule.start_time,
                end_time: exam_schedule.end_time
              },
              number_of_people: @reservation.number_of_people,
              status: @reservation.status,
              created_at: @reservation.created_at,
              updated_at: @reservation.updated_at
            }
          else
            render json: { errors: @reservation.errors }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::LockWaitTimeout
        render json: { error: '다른 사용자가 예약을 수정 중입니다. 나중에 다시 시도해주세요.' }, status: :conflict
      end

      def destroy
        # 비관적 락을 사용하지 않고 삭제 시도
        # 삭제는 동시성 문제가 덜 심각하므로 간단히 처리
        if @reservation.destroy
          head :no_content
        else
          render json: { error: '예약 삭제에 실패했습니다.' }, status: :unprocessable_entity
        end
      end

      def confirm
        ActiveRecord::Base.transaction do
          # 비관적 락 적용: 예약과 시험 일정을 모두 잠급니다
          @reservation.lock!
          @reservation.exam_schedule.lock!
          
          # 예약 확정 시도
          if @reservation.status == 'pending' && @reservation.exam_schedule.can_reserve?(@reservation.number_of_people)
            # 예약 상태 업데이트
            @reservation.update!(status: 'confirmed')
            # 시험 일정의 현재 예약 인원 업데이트
            @reservation.exam_schedule.increment!(:current_reservations, @reservation.number_of_people)
            
            render json: {
              id: @reservation.id,
              status: @reservation.status,
              message: '예약이 확정되었습니다.'
            }
          else
            render json: { 
              error: '예약 확정에 실패했습니다. 가용 인원을 확인해주세요.' 
            }, status: :unprocessable_entity
          end
        end
      rescue ActiveRecord::LockWaitTimeout
        render json: { error: '다른 관리자가 이 예약을 처리 중입니다. 나중에 다시 시도해주세요.' }, status: :conflict
      end

      def cancel
        ActiveRecord::Base.transaction do
          # 비관적 락 적용
          @reservation.lock!
          @reservation.exam_schedule.lock!
          
          # 이미 취소된 예약은 처리하지 않음
          if @reservation.status == 'cancelled'
            return render json: { error: '이미 취소된 예약입니다.' }, status: :unprocessable_entity
          end
          
          # 확정된 예약이었다면 시험 일정의 현재 예약 인원 감소
          was_confirmed = @reservation.status == 'confirmed'
          
          # 예약 상태 업데이트
          @reservation.update!(status: 'cancelled')
          
          # 확정된 예약이었다면 시험 일정의 현재 예약 인원 감소
          if was_confirmed
            @reservation.exam_schedule.decrement!(:current_reservations, @reservation.number_of_people)
          end
          
          render json: {
            id: @reservation.id,
            status: @reservation.status,
            message: '예약이 취소되었습니다.'
          }
        end
      rescue ActiveRecord::LockWaitTimeout
        render json: { error: '다른 사용자가 이 예약을 처리 중입니다. 나중에 다시 시도해주세요.' }, status: :conflict
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

      def authorize_admin
        return if current_admin
        render json: { error: '관리자 권한이 필요합니다.' }, status: :forbidden
      end

      def authorize_modification
        return if @reservation.can_be_modified_by?(current_admin || current_customer)
        render json: { error: '이 예약을 수정/삭제할 권한이 없습니다.' }, status: :forbidden
      end

      def reservation_params
        params.permit(:number_of_people)
      end
    end
  end
end 