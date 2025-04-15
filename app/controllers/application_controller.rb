class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # JSON API 요청의 경우 CSRF 토큰 검증에 실패하더라도 세션만 비우고 요청 자체는 처리한다
  protect_from_forgery with: :null_session, if: -> { request.format.json? }
  
  # 현재 로그인한 고객 정보를 반환
  def current_customer
    return @current_customer if defined?(@current_customer)
    
    customer_id = session[:customer_id]
    @current_customer = Customer.find_by(id: customer_id) if customer_id
  end
  
  # 현재 로그인한 관리자 정보를 반환
  def current_admin
    return @current_admin if defined?(@current_admin)
    
    admin_id = session[:admin_id]
    @current_admin = Admin.find_by(id: admin_id) if admin_id
  end
  
  # 인증된 사용자(고객 또는 관리자)인지 확인
  def authenticate_user!
    return if current_admin || current_customer
    
    render json: { error: '인증이 필요합니다.' }, status: :unauthorized
  end
  
  helper_method :current_customer, :current_admin
end
