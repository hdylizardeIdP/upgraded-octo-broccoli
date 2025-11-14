class ApplicationController < ActionController::API
  # Include validation concern for input sanitization and validation
  include InputValidation

  # Rescue from JWT errors and return appropriate responses
  rescue_from JWT::ExpiredSignature, with: :token_expired
  rescue_from JWT::DecodeError, with: :invalid_token
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # Authenticate user before any action (override with skip_before_action in controllers)
  before_action :authenticate_user!, unless: :devise_controller?

  private

  # Authenticate the user via JWT token
  def authenticate_user!
    header = request.headers['Authorization']

    if header.blank?
      render json: { error: 'Missing authorization token' }, status: :unauthorized
      return
    end

    token = header.split(' ').last

    # Check if token is blacklisted
    if TokenBlacklist.blacklisted?(token)
      render json: { error: 'Token has been revoked' }, status: :unauthorized
      return
    end

    begin
      decoded = JsonWebToken.decode(token)
      user_id = decoded[:user_id]

      # Check if user is blacklisted (e.g., after password change or ban)
      if TokenBlacklist.user_blacklisted?(user_id)
        render json: { error: 'User access has been revoked' }, status: :unauthorized
        return
      end

      @current_user = User.find(user_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :unauthorized
    rescue JWT::ExpiredSignature
      render json: { error: 'Token has expired' }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { error: "Invalid token: #{e.message}" }, status: :unauthorized
    end
  end

  # Get the current token from request headers
  def current_token
    request.headers['Authorization']&.split(' ')&.last
  end

  # Get the current authenticated user
  def current_user
    @current_user
  end

  # Check if user is authenticated
  def user_signed_in?
    current_user.present?
  end

  # Error handlers
  def token_expired
    render json: { error: 'Token has expired' }, status: :unauthorized
  end

  def invalid_token
    render json: { error: 'Invalid token' }, status: :unauthorized
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end

  # Dummy method to avoid errors when checking for Devise
  def devise_controller?
    false
  end
end
