require 'swagger_helper'

RSpec.describe 'API V1 Reservations', type: :request do
  path '/api/v1/reservations' do
    get '예약 목록 조회' do
      tags '예약'
      produces 'application/json'
      security [cookieAuth: [], bearerAuth: []]
      
      response '200', '예약 목록 조회 성공' do
        schema type: :object,
          properties: {
            reservations: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  exam_schedule: {
                    type: :object,
                    properties: {
                      id: { type: :integer },
                      start_time: { type: :string, format: 'date-time' },
                      end_time: { type: :string, format: 'date-time' }
                    }
                  },
                  number_of_people: { type: :integer },
                  status: { type: :string, enum: ['pending', 'confirmed', 'cancelled'] },
                  created_at: { type: :string, format: 'date-time' }
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

    post '예약 등록' do
      tags '예약'
      consumes 'application/json'
      produces 'application/json'
      security [cookieAuth: [], bearerAuth: []]
      
      parameter name: :reservation_params, in: :body, schema: {
        type: :object,
        properties: {
          exam_schedule_id: { type: :integer, example: 1 },
          number_of_people: { type: :integer, example: 10 }
        },
        required: ['exam_schedule_id', 'number_of_people']
      }

      response '201', '예약 등록 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            exam_schedule: {
              type: :object,
              properties: {
                id: { type: :integer },
                start_time: { type: :string, format: 'date-time' },
                end_time: { type: :string, format: 'date-time' }
              }
            },
            number_of_people: { type: :integer },
            status: { type: :string },
            created_at: { type: :string, format: 'date-time' }
          }
        
        run_test!
      end

      response '422', '유효성 검증 실패' do
        schema type: :object,
          properties: {
            errors: { type: :object }
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

  path '/api/v1/reservations/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    get '예약 상세 조회' do
      tags '예약'
      produces 'application/json'
      security [cookieAuth: [], bearerAuth: []]
      
      response '200', '예약 상세 조회 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            exam_schedule: {
              type: :object,
              properties: {
                id: { type: :integer },
                start_time: { type: :string, format: 'date-time' },
                end_time: { type: :string, format: 'date-time' }
              }
            },
            number_of_people: { type: :integer },
            status: { type: :string, enum: ['pending', 'confirmed', 'cancelled'] },
            created_at: { type: :string, format: 'date-time' }
          }
        
        run_test!
      end

      response '404', '예약 찾을 수 없음' do
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

    put '예약 수정' do
      tags '예약'
      consumes 'application/json'
      produces 'application/json'
      security [cookieAuth: [], bearerAuth: []]
      
      parameter name: :reservation_params, in: :body, schema: {
        type: :object,
        properties: {
          number_of_people: { type: :integer, example: 15 }
        },
        required: ['number_of_people']
      }

      response '200', '예약 수정 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            exam_schedule: {
              type: :object,
              properties: {
                id: { type: :integer },
                start_time: { type: :string, format: 'date-time' },
                end_time: { type: :string, format: 'date-time' }
              }
            },
            number_of_people: { type: :integer },
            status: { type: :string },
            created_at: { type: :string, format: 'date-time' },
            updated_at: { type: :string, format: 'date-time' }
          }
        
        run_test!
      end

      response '422', '유효성 검증 실패' do
        schema type: :object,
          properties: {
            errors: { type: :object }
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

      response '403', '권한 없음' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end
    end

    delete '예약 삭제' do
      tags '예약'
      security [cookieAuth: [], bearerAuth: []]
      
      response '204', '예약 삭제 성공' do
        run_test!
      end

      response '401', '인증 실패' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end

      response '403', '권한 없음' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end
    end
  end

  path '/api/v1/reservations/{id}/confirm' do
    parameter name: :id, in: :path, type: :integer, required: true

    post '예약 확정' do
      tags '예약'
      produces 'application/json'
      security [cookieAuth: [], bearerAuth: []]
      
      response '200', '예약 확정 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            status: { type: :string },
            message: { type: :string }
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

      response '403', '권한 없음' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end

      response '422', '처리 불가' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end
    end
  end

  path '/api/v1/reservations/{id}/cancel' do
    parameter name: :id, in: :path, type: :integer, required: true

    post '예약 취소' do
      tags '예약'
      produces 'application/json'
      security [cookieAuth: [], bearerAuth: []]
      
      response '200', '예약 취소 성공' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            status: { type: :string },
            message: { type: :string }
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

      response '403', '권한 없음' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end

      response '422', '처리 불가' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        run_test!
      end
    end
  end
end 