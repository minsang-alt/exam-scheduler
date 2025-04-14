class ExamSchedule < ApplicationRecord
  has_many :reservations

  validates :start_time, :end_time, presence: true
  validates :max_capacity, numericality: { greater_than: 0, less_than_or_equal_to: 50000 }
  validates :current_reservations, numericality: { greater_than_or_equal_to: 0 }

  validate :end_time_after_start_time
  validate :schedule_not_in_past
  validate :capacity_not_exceeded

  def available_capacity
    max_capacity - current_reservations
  end

  # 예약 가능한 인원 수를 반환, 3일 이후부터 예약 가능
  def can_reserve?(number_of_people)
    return false if start_time < 3.days.from_now
    available_capacity >= number_of_people
  end

  private

  # 종료 시간이 시작 시간 이후여야 함
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    if end_time <= start_time
      errors.add(:end_time, "반드시 시작 시간 이후여야 합니다.")
    end
  end

  def schedule_not_in_past
    return if start_time.blank?
    if start_time < Time.current
      errors.add(:start_time, "반드시 현재 시간 이후여야 합니다.")
    end
  end

  def capacity_not_exceeded
    return if current_reservations.blank? || max_capacity.blank?
    if current_reservations > max_capacity
      errors.add(:current_reservations, "최대 인원 수를 초과할 수 없습니다.")
    end
  end
end 