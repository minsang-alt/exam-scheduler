require 'swagger_helper'

RSpec.describe 'API V1 ExamSchedules', type: :request do
  path '/api/v1/exam_schedules' do
    get '시험 일정 목록 조회' do
      tags '시험 일정'
      produces 'application/json'
      security [ cookieAuth: [], bearerAuth: [] ]

      response '200', '시험 일정 목록 조회 성공' do
        schema type: :object,
          properties: {
            schedules: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  start_time: { type: :string, format: 'date-time' },
                  end_time: { type: :string, format: 'date-time' },
                  max_capacity: { type: :integer },
                  current_reservations: { type: :integer },
                  available_capacity: { type: :integer },
                  is_available: { type: :boolean }
                }
              }
            }
          }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end

  path '/api/v1/exam_schedules/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    get '시험 일정 상세 조회' do
      tags '시험 일정'
      produces 'application/json'
      security [ cookieAuth: [], bearerAuth: [] ]

      response '200', '시험 일정 상세 조회 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            start_time: { type: :string, format: 'date-time' },
            end_time: { type: :string, format: 'date-time' },
            max_capacity: { type: :integer },
            current_reservations: { type: :integer },
            available_capacity: { type: :integer },
            is_available: { type: :boolean }
          }

        run_test!
      end

      response '404', '시험 일정 찾을 수 없음' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }

        run_test!
      end
    end
  end
end
