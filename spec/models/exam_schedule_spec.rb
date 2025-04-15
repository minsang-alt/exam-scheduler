require 'rails_helper'

RSpec.describe ExamSchedule, type: :model do
  describe '유효성 검증' do
    it '유효한 시험 일정은 저장할 수 있다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: true
      )
      expect(exam_schedule).to be_valid
    end

    it '시작 시간이 없으면 유효하지 않다' do
      exam_schedule = ExamSchedule.new(
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:start_time]).to include("can't be blank")
    end

    it '종료 시간이 없으면 유효하지 않다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        max_capacity: 50000,
        current_reservations: 0
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:end_time]).to include("can't be blank")
    end

    it '최대 수용 인원은 1명 이상이어야 한다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 0,
        current_reservations: 0
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:max_capacity]).to include("must be greater than 0")
    end

    it '최대 수용 인원은 50000명을 초과할 수 없다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50001,
        current_reservations: 0
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:max_capacity]).to include("must be less than or equal to 50000")
    end

    it '종료 시간은 시작 시간 이후여야 한다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now - 1.hour,
        max_capacity: 50000,
        current_reservations: 0
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:end_time]).to include("반드시 시작 시간 이후여야 합니다.")
    end

    it '시작 시간은 현재 시간 이후여야 한다' do
      exam_schedule = ExamSchedule.new(
        start_time: 1.day.ago,
        end_time: 1.day.ago + 2.hours,
        max_capacity: 50000,
        current_reservations: 0
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:start_time]).to include("반드시 현재 시간 이후여야 합니다.")
    end

    it '현재 예약 인원은 최대 수용 인원을 초과할 수 없다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 50001
      )
      expect(exam_schedule).not_to be_valid
      expect(exam_schedule.errors[:current_reservations]).to include("최대 인원 수를 초과할 수 없습니다.")
    end
  end

  describe '#available_capacity' do
    it '가용 인원을 정확히 계산한다' do
      exam_schedule = ExamSchedule.new(
        max_capacity: 50000,
        current_reservations: 30000
      )
      expect(exam_schedule.available_capacity).to eq(20000)
    end
  end

  describe '#can_reserve?' do
    it '시작 시간이 3일 이내면 예약할 수 없다' do
      exam_schedule = ExamSchedule.new(
        start_time: 2.days.from_now,
        end_time: 2.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0
      )
      expect(exam_schedule.can_reserve?(10)).to be_falsey
    end

    it '가용 인원이 요청 인원보다 적으면 예약할 수 없다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 49990
      )
      expect(exam_schedule.can_reserve?(20)).to be_falsey
    end

    it '시작 시간이 3일 이후이고 가용 인원이 충분하면 예약할 수 있다' do
      exam_schedule = ExamSchedule.new(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 30000
      )
      expect(exam_schedule.can_reserve?(20000)).to be_truthy
    end
  end

  describe '.available_schedules' do
    it '시작 시간이 3일 이후인 시험 일정만 반환한다' do
      past_schedule = ExamSchedule.create!(
        start_time: 2.days.from_now,
        end_time: 2.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: true
      )

      future_schedule = ExamSchedule.create!(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: true
      )

      unavailable_schedule = ExamSchedule.create!(
        start_time: 5.days.from_now,
        end_time: 5.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: false
      )

      available_schedules = ExamSchedule.available_schedules
      expect(available_schedules).to include(future_schedule)
      expect(available_schedules).not_to include(past_schedule)
      expect(available_schedules).not_to include(unavailable_schedule)
    end
  end
end
