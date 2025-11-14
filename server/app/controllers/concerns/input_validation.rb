# Input Validation Concern
# Provides common validation utilities for controllers
# Helps prevent injection attacks and ensures data integrity

module InputValidation
  extend ActiveSupport::Concern

  included do
    # Rescue from ActionController::ParameterMissing for better error messages
    rescue_from ActionController::ParameterMissing do |exception|
      render json: {
        error: 'Missing required parameter',
        message: exception.message,
        param: exception.param
      }, status: :bad_request
    end

    # Rescue from invalid parameter format
    rescue_from ActionController::UnpermittedParameters do |exception|
      render json: {
        error: 'Unpermitted parameters',
        message: 'One or more parameters are not allowed',
        params: exception.params
      }, status: :bad_request
    end
  end

  private

  # Validate UUID format
  # @param uuid [String] The UUID to validate
  # @return [Boolean] true if valid UUID format
  def valid_uuid?(uuid)
    uuid.to_s.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
  end

  # Validate date format (YYYY-MM-DD)
  # @param date [String] The date string to validate
  # @return [Boolean] true if valid date format
  def valid_date?(date)
    return false if date.blank?
    Date.parse(date.to_s)
    true
  rescue ArgumentError
    false
  end

  # Sanitize search query to prevent SQL injection
  # @param query [String] The search query
  # @return [String] Sanitized query
  def sanitize_search_query(query)
    return '' if query.blank?

    # Remove special SQL characters
    query.to_s.gsub(/[';\"\\]/, '')
  end

  # Validate numeric parameter
  # @param value [String, Numeric] The value to validate
  # @param min [Numeric] Minimum allowed value (optional)
  # @param max [Numeric] Maximum allowed value (optional)
  # @return [Boolean] true if valid number within range
  def valid_number?(value, min: nil, max: nil)
    return false if value.blank?

    num = Float(value)
    return false if num.nan? || num.infinite?
    return false if min && num < min
    return false if max && num > max

    true
  rescue ArgumentError, TypeError
    false
  end

  # Validate pagination parameters
  # @param page [String, Integer] Page number
  # @param per_page [String, Integer] Items per page
  # @return [Hash] Sanitized pagination params
  def validate_pagination(page: 1, per_page: 30)
    page = [page.to_i, 1].max
    per_page = [[per_page.to_i, 1].max, 100].min  # Max 100 items per page

    { page: page, per_page: per_page }
  end

  # Validate email format
  # @param email [String] The email to validate
  # @return [Boolean] true if valid email format
  def valid_email?(email)
    return false if email.blank?
    email.to_s.match?(URI::MailTo::EMAIL_REGEXP)
  end

  # Sanitize filename to prevent directory traversal
  # @param filename [String] The filename to sanitize
  # @return [String] Sanitized filename
  def sanitize_filename(filename)
    return '' if filename.blank?

    # Remove path separators and special characters
    filename.to_s.gsub(/[\/\\:*?"<>|]/, '_')
  end

  # Validate JSON structure
  # @param json_string [String] The JSON string to validate
  # @return [Boolean] true if valid JSON
  def valid_json?(json_string)
    return false if json_string.blank?
    JSON.parse(json_string)
    true
  rescue JSON::ParserError
    false
  end

  # Check for common injection patterns
  # @param input [String] The input to check
  # @return [Boolean] true if input appears safe
  def safe_input?(input)
    return true if input.blank?

    dangerous_patterns = [
      /<script/i,                    # XSS
      /javascript:/i,                # XSS
      /on\w+\s*=/i,                  # Event handlers
      /union.*select/i,              # SQL injection
      /insert.*into/i,               # SQL injection
      /drop.*table/i,                # SQL injection
      /\.\.\/|\.\.\\\/,              # Directory traversal
      /<\?php/i,                     # PHP code injection
      /<%.*%>/                       # Template injection
    ]

    !dangerous_patterns.any? { |pattern| input.to_s.match?(pattern) }
  end
end
