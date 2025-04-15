# 시험 일정 예약 시스템 API

온라인 시험 플랫폼에서 시험 일정을 관리하고 예약할 수 있는 RESTful API 백엔드 시스템입니다.

## 주요 기능

- 사용자 인증 (관리자/고객)
- 시험 일정 관리 및 조회
- 시험 예약 생성, 확인, 취소
- 예약 가능 인원 자동 관리

## 기술 스택

- **백엔드**: Ruby on Rails 8.0
- **데이터베이스**: PostgreSQL
- **인증**: JWT (JSON Web Token)
- **API 문서화**: Swagger
- **테스트**: RSpec
- **배포**: Docker & Kamal

## 데이터베이스 스키마

![데이터베이스 스키마](dbscheme.png)

## 환경 설정 및 실행 방법

### 필수 조건

- Ruby 3.2 이상
- PostgreSQL 14 이상
- Docker (선택사항, 컨테이너 실행 시)

### 로컬 환경 설정

1. 저장소 클론

```bash
git clone https://github.com/minsang-alt/exam-scheduler.git
cd exam-scheduler
```

2. 의존성 설치

```bash
bundle install
```

3. 데이터베이스 생성 및 마이그레이션

```bash
bin/rails db:create
bin/rails db:migrate
```

4. 테스트 데이터 생성 (선택사항)

```bash
bin/rails db:seed
```

5. 서버 실행

```bash
bin/rails server
```

서버는 기본적으로 http://localhost:3000 에서 실행됩니다.

### Docker를 사용한 실행

1. 도커 이미지 빌드

```bash
docker build -t exam-scheduler .
```

2. 컨테이너 실행

```bash
docker run -p 3000:3000 -e DATABASE_URL=postgresql://user:password@host:port/dbname exam-scheduler
```

## API 문서

API 문서는 Swagger UI를 통해 제공됩니다. 서버 실행 후 다음 URL에서 확인할 수 있습니다:

```
http://localhost:3000/api-docs
```

### 주요 API 엔드포인트

#### 인증 API

- `POST /api/v1/auth/register` - 회원가입
- `POST /api/v1/auth/login` - 로그인
- `DELETE /api/v1/auth/logout` - 로그아웃

#### 시험 일정 API

- `GET /api/v1/exam_schedules` - 시험 일정 목록 조회
- `GET /api/v1/exam_schedules/:id` - 특정 시험 일정 조회

#### 예약 API

- `POST /api/v1/reservations` - 예약 생성
- `GET /api/v1/reservations` - 사용자 예약 목록 조회
- `GET /api/v1/reservations/:id` - 특정 예약 조회
- `PUT /api/v1/reservations/:id` - 예약 수정
- `DELETE /api/v1/reservations/:id` - 예약 삭제
- `POST /api/v1/reservations/:id/confirm` - 예약 확정
- `POST /api/v1/reservations/:id/cancel` - 예약 취소

## 테스트 실행

```bash
bundle exec rspec
```

## API 예시 요청

### 로그인 예시

```bash
curl -X POST "http://localhost:3000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "user_type": "customer"
  }'
```

### 시험 일정 조회 예시

```bash
curl -X GET "http://localhost:3000/api/v1/exam_schedules" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 예약 생성 예시

```bash
curl -X POST "http://localhost:3000/api/v1/reservations" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "exam_schedule_id": 1,
    "number_of_people": 2
  }'
```

---

임시 사용자 아이디 및 비번: user@example.com , password123 , customer
임시 관리자 아이디 및 비번: admin@example.com, password123 , admin
