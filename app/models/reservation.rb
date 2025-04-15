class Reservation < ApplicationRecord
  belongs_to :exam_schedule
  belongs_to :customer

  validates :number_of_people, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending confirmed cancelled] }

  before_validation :set_default_status
  before_save :update_exam_schedule_capacity

  /*
  예약 수정 가능 여부 확인
  - 관리자는 모든 예약을 수정할 수 있음
  - 고객은 예약 상태가 pending인 경우에만 수정할 수 있음
  */
  def can_be_modified_by?(user)
    return true if user.is_a?(Admin)
    return false unless user.is_a?(Customer)
    customer_id == user.id && status == 'pending'
  end

  /*
  예약 삭제 가능 여부 확인
  - 관리자는 모든 예약을 삭제할 수 있음
  - 고객은 예약 상태가 pending인 경우에만 삭제할 수 있음
  */
  def can_be_deleted_by?(user)
    return true if user.is_a?(Admin)
    return false unless user.is_a?(Customer)
    customer_id == user.id && status == 'pending'
  end

  /*
  예약 확정 가능 여부 확인
  - 관리자만 확정할 수 있음
  */
  def can_be_confirmed_by?(user)
    user.is_a?(Admin)
  end

  def confirm!
    return false unless exam_schedule.can_reserve?(number_of_people)
    
    ActiveRecord::Base.transaction do
      # 비관적 락 적용
      locked_schedule = ExamSchedule.lock('FOR UPDATE').find(exam_schedule.id)
      
      if locked_schedule.can_reserve?(number_of_people)
        update!(status: 'confirmed')
        locked_schedule.increment!(:current_reservations, number_of_people)
        true
      else
        false
      end
    end
  rescue ActiveRecord::LockWaitTimeout
    false
  end

  def cancel!
    return false if status == 'cancelled'
    
    ActiveRecord::Base.transaction do
      # 비관적 락 적용
      locked_schedule = ExamSchedule.lock('FOR UPDATE').find(exam_schedule.id)
      
      update!(status: 'cancelled')
      locked_schedule.decrement!(:current_reservations, number_of_people) if status == 'confirmed'
      true
    end
  rescue ActiveRecord::LockWaitTimeout
    false
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def update_exam_schedule_capacity
    return unless status_changed? && status == 'confirmed'
    exam_schedule.increment!(:current_reservations, number_of_people)
  end
end 