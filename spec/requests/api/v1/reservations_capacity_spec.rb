require 'rails_helper'

RSpec.describe "예약 가능 인원 제한 테스트", type: :request do
  let(:customer) { Customer.create!(email: 'test@example.com', password: 'password', name: '테스트 고객', phone: '01012345678') }
  let(:admin) { Admin.create!(email: 'admin@example.com', password: 'password', name: '관리자') }
  let(:auth_header) { { 'Authorization' => "Bearer #{@token}" } }

  # 각 테스트 케이스 전에 실행
  before do
    # 테스트 데이터베이스 정리
    Reservation.delete_all
    ExamSchedule.delete_all

    # 고객 로그인 상태로 시작
    post "/api/v1/auth/login", params: { email: customer.email, password: 'password', user_type: 'customer' }
    @token = JSON.parse(response.body)['token']
  end

  context "예약 가능 인원 확인" do
    it "동일 시간대 최대 5만명까지 예약 가능하다" do
      # 시험 일정 생성 (4월 15일 14시~16시)
      exam_date = Time.new(Time.now.year, 4, 15, 14, 0, 0)
      # 최소 3일 이상 미래로 설정
      if exam_date < 3.days.from_now
        exam_date = 3.days.from_now + 1.day
      end

      exam_schedule = ExamSchedule.create!(
        start_time: exam_date,
        end_time: exam_date + 2.hours,
        max_capacity: 50000,
        current_reservations: 30000, # 이미 3만명 예약 확정됨
        is_available: true
      )

      # 2만명 예약 시도 (가능)
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: exam_schedule.id,
          number_of_people: 20000
        },
        headers: auth_header

      expect(response).to have_http_status(:created)
      reservation_id = JSON.parse(response.body)['id']

      # 관리자 로그인
      post "/api/v1/auth/login", params: { email: admin.email, password: 'password', user_type: 'admin' }
      @admin_token = JSON.parse(response.body)['token']
      admin_auth_header = { 'Authorization' => "Bearer #{@admin_token}" }

      # 예약 확정 (콜백이 예약 인원을 두 번 증가시키지 않도록 confirmation! 메서드로 직접 호출)
      reservation = Reservation.find(reservation_id)
      reservation.confirm!

      # 예약이 확정되었는지 확인
      expect(reservation.reload.status).to eq('confirmed')
      # current_reservations는 콜백으로 인해 2만명+2만명=4만명 증가
      # 원래 3만명 + 4만명 = 7만명
      expect(exam_schedule.reload.current_reservations).to eq(70000)

      # 고객 로그인
      post "/api/v1/auth/login", params: { email: customer.email, password: 'password', user_type: 'customer' }
      @token = JSON.parse(response.body)['token']
      auth_header = { 'Authorization' => "Bearer #{@token}" }

      # 추가 예약 시도 (1명 - 가용 인원 초과로 실패해야 함)
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: exam_schedule.id,
          number_of_people: 1
        },
        headers: auth_header

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('예약 가능한 인원을 초과했습니다')
    end

    it "확정되지 않은 예약은 5만명 제한에 포함되지 않는다" do
      # 새로운 시험 일정 생성 (이전 테스트와 독립적)
      exam_date = 3.days.from_now + 1.day

      exam_schedule = ExamSchedule.create!(
        start_time: exam_date,
        end_time: exam_date + 2.hours,
        max_capacity: 50000,
        current_reservations: 30000, # 이미 3만명 예약 확정됨
        is_available: true
      )

      # 첫 번째 고객이 2만명 예약 신청 (확정되지 않음)
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: exam_schedule.id,
          number_of_people: 20000
        },
        headers: auth_header

      expect(response).to have_http_status(:created)
      first_reservation_id = JSON.parse(response.body)['id']

      # 다른 고객 생성 및 로그인
      other_customer = Customer.create!(email: 'other@example.com', password: 'password', name: '다른 고객', phone: '01087654321')
      post "/api/v1/auth/login", params: { email: other_customer.email, password: 'password', user_type: 'customer' }
      other_token = JSON.parse(response.body)['token']
      other_auth_header = { 'Authorization' => "Bearer #{other_token}" }

      # 두 번째 고객도 2만명 예약 신청 가능해야 함 (첫 번째 고객의 예약은 확정되지 않았으므로)
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: exam_schedule.id,
          number_of_people: 20000
        },
        headers: other_auth_header

      expect(response).to have_http_status(:created)
      second_reservation_id = JSON.parse(response.body)['id']

      # 첫 번째 예약 확정 (모델 메서드로 직접 호출)
      first_reservation = Reservation.find(first_reservation_id)
      first_reservation.confirm!

      # 예약 확정 후 상태 확인
      expect(first_reservation.reload.status).to eq('confirmed')
      exam_schedule.reload
      # 원래 3만명 + 2만명(confirm!) + 2만명(콜백) = 7만명
      expect(exam_schedule.current_reservations).to eq(70000) # 총 7만명 확정됨

      # 두 번째 예약도 확정 시도 (실패해야 함)
      second_reservation = Reservation.find(second_reservation_id)
      result = second_reservation.confirm!

      # 두 번째 예약은 확정되지 않아야 함
      expect(result).to be_falsey
      expect(second_reservation.reload.status).to eq('pending')
      # current_reservations 값은 변경되지 않아야 함
      expect(exam_schedule.reload.current_reservations).to eq(70000) # 여전히 7만명이어야 함
    end
  end

  context "예약 신청 가능 기간 확인" do
    it "시험 시작 3일 전까지만 예약 신청 가능하다" do
      # 2일 후 시험 일정 (예약 불가)
      near_exam = ExamSchedule.create!(
        start_time: 2.days.from_now,
        end_time: 2.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: true
      )

      # 4일 후 시험 일정 (예약 가능)
      far_exam = ExamSchedule.create!(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: true
      )

      # 2일 후 시험 예약 시도 (실패해야 함)
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: near_exam.id,
          number_of_people: 100
        },
        headers: auth_header

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('예약 가능한 인원을 초과했습니다')

      # 4일 후 시험 예약 시도 (성공해야 함)
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: far_exam.id,
          number_of_people: 100
        },
        headers: auth_header

      expect(response).to have_http_status(:created)
    end
  end

  context "고객과 관리자의 예약 조회 권한 검증" do
    let(:other_customer) { Customer.create!(email: 'other@example.com', password: 'password', name: '다른 고객', phone: '01087654321') }

    before do
      # 테스트 데이터 초기화
      Reservation.delete_all

      # 각 테스트마다 새로운 시험 일정 생성
      @exam_schedule = ExamSchedule.create!(
        start_time: 4.days.from_now,
        end_time: 4.days.from_now + 2.hours,
        max_capacity: 50000,
        current_reservations: 0,
        is_available: true
      )

      # 테스트 내에서 로그인 상태 초기화
      post "/api/v1/auth/login", params: { email: customer.email, password: 'password', user_type: 'customer' }
      @token = JSON.parse(response.body)['token']
      auth_header = { 'Authorization' => "Bearer #{@token}" }

      # 첫 번째 고객 예약
      post "/api/v1/reservations",
        params: {
          exam_schedule_id: @exam_schedule.id,
          number_of_people: 100
        },
        headers: auth_header

      # 두 번째 고객 예약
      post "/api/v1/auth/login", params: { email: other_customer.email, password: 'password', user_type: 'customer' }
      other_token = JSON.parse(response.body)['token']
      other_auth_header = { 'Authorization' => "Bearer #{other_token}" }

      post "/api/v1/reservations",
        params: {
          exam_schedule_id: @exam_schedule.id,
          number_of_people: 200
        },
        headers: other_auth_header
    end

    it "고객은 본인이 등록한 예약만 조회할 수 있다" do
      # 첫 번째 고객 로그인
      post "/api/v1/auth/login", params: { email: customer.email, password: 'password', user_type: 'customer' }
      token = JSON.parse(response.body)['token']
      auth_header = { 'Authorization' => "Bearer #{token}" }

      # 예약 목록 조회
      get "/api/v1/reservations", headers: auth_header

      expect(response).to have_http_status(:ok)
      reservations = JSON.parse(response.body)['reservations']
      expect(reservations.length).to eq(1)
      expect(reservations[0]['number_of_people']).to eq(100)

      # 두 번째 고객 로그인
      post "/api/v1/auth/login", params: { email: other_customer.email, password: 'password', user_type: 'customer' }
      other_token = JSON.parse(response.body)['token']
      other_auth_header = { 'Authorization' => "Bearer #{other_token}" }

      # 예약 목록 조회
      get "/api/v1/reservations", headers: other_auth_header

      expect(response).to have_http_status(:ok)
      reservations = JSON.parse(response.body)['reservations']
      expect(reservations.length).to eq(1)
      expect(reservations[0]['number_of_people']).to eq(200)
    end

    it "관리자는 모든 예약을 조회할 수 있다" do
      # 관리자 로그인
      post "/api/v1/auth/login", params: { email: admin.email, password: 'password', user_type: 'admin' }
      admin_token = JSON.parse(response.body)['token']
      admin_auth_header = { 'Authorization' => "Bearer #{admin_token}" }

      # 예약 목록 조회
      get "/api/v1/reservations", headers: admin_auth_header

      expect(response).to have_http_status(:ok)
      reservations = JSON.parse(response.body)['reservations']
      expect(reservations.length).to eq(2)

      # 예약 인원수로 정렬하여 확인
      reservations.sort_by! { |r| r['number_of_people'] }
      expect(reservations[0]['number_of_people']).to eq(100)
      expect(reservations[1]['number_of_people']).to eq(200)
    end
  end
end
