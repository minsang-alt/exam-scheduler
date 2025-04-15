class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # JSON API 요청의 경우 CSRF 토큰 검증에 실패하더라도 세션만 비우고 요청 자체는 처리한다
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  # JWT 시크릿 키
  JWT_SECRET = "grepp_secret_key_for_jwt_token_24x74u28x9c7w8"

  # 현재 로그인한 고객 정보를 반환
  def current_customer
    return @current_customer if defined?(@current_customer)

    # 세션 기반 인증
    customer_id = session[:customer_id]
    @current_customer = Customer.find_by(id: customer_id) if customer_id

    # JWT 토큰 기반 인증 (세션 인증이 없는 경우)
    if @current_customer.nil? && auth_header.present?
      Rails.logger.debug "Auth header present: #{auth_header}"
      token = auth_header.split(" ").last
      Rails.logger.debug "Token: #{token}"
      payload = jwt_decode(token)
      Rails.logger.debug "Payload: #{payload.inspect}"
      if payload && payload["user_type"] == "customer"
        @current_customer = Customer.find_by(id: payload["user_id"])
        Rails.logger.debug "Found customer: #{@current_customer.inspect}"
      end
    end

    @current_customer
  end

  # 현재 로그인한 관리자 정보를 반환
  def current_admin
    return @current_admin if defined?(@current_admin)

    # 세션 기반 인증
    admin_id = session[:admin_id]
    @current_admin = Admin.find_by(id: admin_id) if admin_id

    # JWT 토큰 기반 인증 (세션 인증이 없는 경우)
    if @current_admin.nil? && auth_header.present?
      Rails.logger.debug "Auth header present: #{auth_header}"
      token = auth_header.split(" ").last
      Rails.logger.debug "Token: #{token}"
      payload = jwt_decode(token)
      Rails.logger.debug "Payload: #{payload.inspect}"
      if payload && payload["user_type"] == "admin"
        @current_admin = Admin.find_by(id: payload["user_id"])
        Rails.logger.debug "Found admin: #{@current_admin.inspect}"
      end
    end

    @current_admin
  end

  # 인증된 사용자(고객 또는 관리자)인지 확인
  def authenticate_user!
    Rails.logger.debug "Authenticating user..."
    Rails.logger.debug "Session: #{session.inspect}"
    Rails.logger.debug "Auth header: #{auth_header}"

    return if current_admin || current_customer

    render json: { error: "인증이 필요합니다." }, status: :unauthorized
  end

  # JWT 토큰 생성
  def jwt_encode(payload)
    JWT.encode(payload, JWT_SECRET)
  end

  # JWT 토큰 디코드
  def jwt_decode(token)
    begin
      decoded = JWT.decode(token, JWT_SECRET, true, algorithm: "HS256")[0]
      HashWithIndifferentAccess.new(decoded)
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError => e
      Rails.logger.debug "JWT decode error: #{e.message}"
      nil
    end
  end

  # Authorization 헤더 값 반환
  def auth_header
    request.headers["Authorization"]
  end

  helper_method :current_customer, :current_admin
end
