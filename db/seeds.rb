# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 기존 데이터 삭제 (기존 데이터를 유지하려면 이 부분을 주석 처리하세요)
puts "기존 데이터 삭제 중..."
Reservation.delete_all
ExamSchedule.delete_all
Customer.delete_all
Admin.delete_all
puts "기존 데이터 삭제 완료"

# 관리자 계정 생성
admin = Admin.find_or_create_by!(email: 'admin@example.com') do |admin|
  admin.name = '관리자'
  admin.password = 'password123'
  admin.password_confirmation = 'password123'
  puts "관리자 계정 생성 완료: #{admin.email}"
end

# 고객 계정 생성 (5명)
customers = []
5.times do |i|
  customer = Customer.find_or_create_by!(email: "customer#{i+1}@example.com") do |customer|
    customer.name = "고객#{i+1}"
    # 전화번호는 10~11자리 숫자여야 함 (앞 부분은 010으로 시작)
    customer.phone = "01012345#{"%03d" % (i+678)}"
    customer.password = 'password123'
    customer.password_confirmation = 'password123'
    puts "고객 계정 생성 완료: #{customer.email}, 전화번호: #{customer.phone}"
  end
  customers << customer
end

# 2025년 4월 20일 이후 시험 일정 생성 (8개)
start_date = Date.new(2025, 4, 20)
exam_schedules = []

8.times do |i|
  # 2일 간격으로 시험 일정 생성
  exam_date = start_date + (i * 2).days
  start_time = exam_date.to_time.change(hour: 10) # 오전 10시 시작
  end_time = start_time + 3.hours # 3시간 시험

  exam_schedule = ExamSchedule.find_or_create_by!(start_time: start_time) do |schedule|
    schedule.end_time = end_time
    schedule.max_capacity = 50000
    schedule.current_reservations = 0
    schedule.is_available = true
    puts "시험 일정 생성 완료: #{schedule.start_time.strftime('%Y-%m-%d %H:%M')}"
  end

  exam_schedules << exam_schedule
end

# 예약 데이터 생성 (각 고객당 1~2개의 예약)
puts "예약 데이터 생성 중..."
customers.each do |customer|
  # 각 고객마다 랜덤하게 1~2개의 예약 생성
  reservations_count = rand(1..2)

  reservations_count.times do
    # 랜덤한 시험 일정 선택
    exam_schedule = exam_schedules.sample

    # 이미 해당 고객이 같은 시험에 예약했는지 확인
    next if Reservation.exists?(customer: customer, exam_schedule: exam_schedule)

    # 랜덤한 인원수 (1~3명)
    number_of_people = rand(1..3)

    # 랜덤한 상태 (pending, confirmed, cancelled 중 하나)
    status = [ 'pending', 'confirmed', 'cancelled' ].sample

    reservation = Reservation.create!(
      exam_schedule: exam_schedule,
      customer: customer,
      number_of_people: number_of_people,
      status: status
    )

    # 예약 인원수만큼 시험 일정의 현재 예약 인원 증가 (cancelled 상태가 아닌 경우에만)
    if status != 'cancelled'
      exam_schedule.increment!(:current_reservations, number_of_people)
    end

    puts "예약 생성 완료: 고객 #{customer.name}, 시험일 #{exam_schedule.start_time.strftime('%Y-%m-%d')}, 인원 #{number_of_people}명, 상태: #{status}"
  end
end

puts "더미 데이터 생성 완료!"
puts "----------------------------"
puts "생성된 데이터 요약:"
puts "관리자: #{Admin.count}명"
puts "고객: #{Customer.count}명"
puts "시험 일정: #{ExamSchedule.count}개"
puts "예약: #{Reservation.count}개"
puts "----------------------------"
puts "로그인 정보:"
puts "관리자 - 이메일: admin@example.com, 비밀번호: password123"
puts "고객 - 이메일: customer1@example.com ~ customer5@example.com, 비밀번호: password123"
