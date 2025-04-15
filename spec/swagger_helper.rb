# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: '시험 일정 예약 시스템 API',
        version: 'v1',
        description: '프로그래머스가 운영하는 온라인 시험 플랫폼 예약 시스템 API'
      },
      servers: [
        {
          url: 'http://localhost:3000',
          description: '개발 서버'
        }
      ],
      components: {
        schemas: {
          Customer: {
            type: 'object',
            required: [ 'name', 'email', 'phone', 'password' ],
            properties: {
              id: { type: 'integer', format: 'int64' },
              name: { type: 'string' },
              email: { type: 'string', format: 'email' },
              phone: { type: 'string' }
            }
          },
          Admin: {
            type: 'object',
            required: [ 'name', 'email', 'password' ],
            properties: {
              id: { type: 'integer', format: 'int64' },
              name: { type: 'string' },
              email: { type: 'string', format: 'email' }
            }
          },
          ExamSchedule: {
            type: 'object',
            required: [ 'start_time', 'end_time' ],
            properties: {
              id: { type: 'integer', format: 'int64' },
              start_time: { type: 'string', format: 'date-time' },
              end_time: { type: 'string', format: 'date-time' },
              max_capacity: { type: 'integer' },
              current_reservations: { type: 'integer' },
              is_available: { type: 'boolean' }
            }
          },
          Reservation: {
            type: 'object',
            required: [ 'exam_schedule_id', 'number_of_people' ],
            properties: {
              id: { type: 'integer', format: 'int64' },
              exam_schedule_id: { type: 'integer', format: 'int64' },
              number_of_people: { type: 'integer' },
              status: { type: 'string', enum: [ 'pending', 'confirmed', 'cancelled' ] }
            }
          }
        },
        securitySchemes: {
          cookieAuth: {
            type: 'apiKey',
            in: 'cookie',
            name: 'session'
          },
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT'
          }
        }
      },
      paths: {}
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The swagger_docs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.swagger_format = :yaml
end
