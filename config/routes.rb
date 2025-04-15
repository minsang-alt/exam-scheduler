Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      # 시험 일정 관련
      resources :exam_schedules, only: [ :index, :show ]

      # 예약 관련
      resources :reservations, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post :confirm  # 예약 확정
          post :cancel   # 예약 취소
        end
      end

      # 인증 관련
      post "auth/login", to: "auth#login"      # 로그인
      post "auth/register", to: "auth#register" # 회원가입
      delete "auth/logout", to: "auth#logout"   # 로그아웃
    end
  end
end
