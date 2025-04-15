require 'swagger_helper'

RSpec.describe 'API V1 Auth', type: :request do
  path '/api/v1/auth/login' do
    post '로그인' do
      tags '인증'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :login_params, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string, example: 'user@example.com' },
          password: { type: :string, example: 'password123' },
          user_type: { type: :string, enum: [ 'customer', 'admin' ], example: 'customer' }
        },
        required: [ 'email', 'password', 'user_type' ]
      }

      response '200', '로그인 성공' do
        schema type: :object,
          properties: {
            message: { type: :string },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                name: { type: :string },
                email: { type: :string },
                user_type: { type: :string }
              }
            },
            token: { type: :string }
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

  path '/api/v1/auth/register' do
    post '회원가입' do
      tags '인증'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :register_params, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string, example: '홍길동' },
          email: { type: :string, example: 'user@example.com' },
          phone: { type: :string, example: '01012345678' },
          password: { type: :string, example: 'password123' },
          password_confirmation: { type: :string, example: 'password123' },
          user_type: { type: :string, enum: [ 'customer' ], example: 'customer' }
        },
        required: [ 'name', 'email', 'phone', 'password', 'password_confirmation', 'user_type' ]
      }

      response '201', '회원가입 성공' do
        schema type: :object,
          properties: {
            message: { type: :string },
            user: {
              type: :object,
              properties: {
                id: { type: :integer },
                name: { type: :string },
                email: { type: :string },
                user_type: { type: :string }
              }
            },
            token: { type: :string }
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
    end
  end

  path '/api/v1/auth/logout' do
    delete '로그아웃' do
      tags '인증'
      produces 'application/json'

      response '200', '로그아웃 성공' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }

        run_test!
      end
    end
  end
end
