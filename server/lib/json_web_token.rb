class JsonWebToken
  # Secret key to encode/decode tokens
  SECRET_KEY = Rails.application.credentials.secret_key_base || ENV['JWT_SECRET']

  # Encode a payload into a JWT token
  # @param payload [Hash] The data to encode
  # @param exp [Integer] Expiration time in hours (default: 24)
  # @return [String] The JWT token
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  # Decode a JWT token
  # @param token [String] The JWT token to decode
  # @return [HashWithIndifferentAccess] The decoded payload
  # @raise [JWT::DecodeError] If token is invalid or expired
  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature
    raise JWT::ExpiredSignature, 'Token has expired'
  rescue JWT::DecodeError => e
    raise JWT::DecodeError, "Invalid token: #{e.message}"
  end
end
