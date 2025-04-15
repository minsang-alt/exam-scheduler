class Api::V1::AuthController < ApplicationController
  def login
    # 고객 로그인 처리
    if params[:email].present? && params[:password].present? && params[:user_type] == 'customer'
      customer = Customer.find_by(email: params[:email])
      
      if customer&.authenticate(params[:password])
        # 세션에 고객 ID 저장
        session[:customer_id] = customer.id
        
        # JWT 토큰 생성
        token = jwt_encode({ user_id: customer.id, user_type: 'customer', exp: 24.hours.from_now.to_i })
        
        render json: {
          message: '로그인 성공',
          user: {
            id: customer.id,
            name: customer.name,
            email: customer.email,
            user_type: 'customer'
          },
          token: token
        }
        return
      end
    end
    
    # 관리자 로그인 처리
    if params[:email].present? && params[:password].present? && params[:user_type] == 'admin'
      admin = Admin.find_by(email: params[:email])
      
      if admin&.authenticate(params[:password])
        # 세션에 관리자 ID 저장
        session[:admin_id] = admin.id
        
        # JWT 토큰 생성
        token = jwt_encode({ user_id: admin.id, user_type: 'admin', exp: 24.hours.from_now.to_i })
        
        render json: {
          message: '로그인 성공',
          user: {
            id: admin.id,
            name: admin.name,
            email: admin.email,
            user_type: 'admin'
          },
          token: token
        }
        return
      end
    end
    
    # 로그인 실패
    render json: { error: '이메일 또는 비밀번호가 올바르지 않습니다.' }, status: :unauthorized
  end

  def register
    # 고객 회원가입 처리
    if params[:user_type] == 'customer'
      customer = Customer.new(
        name: params[:name],
        email: params[:email],
        phone: params[:phone],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )
      
      if customer.save
        # 세션에 고객 ID 저장
        session[:customer_id] = customer.id
        
        # JWT 토큰 생성
        token = jwt_encode({ user_id: customer.id, user_type: 'customer', exp: 24.hours.from_now.to_i })
        
        render json: {
          message: '회원가입 성공',
          user: {
            id: customer.id,
            name: customer.name,
            email: customer.email,
            user_type: 'customer'
          },
          token: token
        }, status: :created
      else
        render json: { errors: customer.errors }, status: :unprocessable_entity
      end
    else
      render json: { error: '지원하지 않는 사용자 유형입니다.' }, status: :unprocessable_entity
    end
  end
  
  def logout
    # 세션 초기화
    reset_session
    render json: { message: '로그아웃 성공' }
  end
  
  private
  
  def auth_params
    params.permit(:email, :password, :password_confirmation, :name, :phone, :user_type)
  end
end
