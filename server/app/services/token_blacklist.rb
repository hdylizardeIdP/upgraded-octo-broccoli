# Token Blacklist Service
# Uses Redis to maintain a list of revoked/blacklisted JWT tokens
# Tokens are automatically removed from the blacklist when they expire

class TokenBlacklist
  # Redis connection
  def self.redis
    @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
  end

  # Add a token to the blacklist
  # @param token [String] The JWT token to blacklist
  # @param ttl [Integer] Time to live in seconds (optional, defaults to token expiration)
  # @return [Boolean] true if successfully added
  def self.add(token, ttl: nil)
    return false if token.blank?

    # Extract expiration from token if TTL not provided
    ttl ||= extract_ttl(token)

    # Store in Redis with expiration
    # Key format: "blacklist:token:{token}"
    key = "blacklist:token:#{token}"

    if ttl && ttl > 0
      redis.setex(key, ttl, '1')
      true
    else
      # Token is already expired, no need to blacklist
      false
    end
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.add failed: #{e.message}")
    false
  end

  # Check if a token is blacklisted
  # @param token [String] The JWT token to check
  # @return [Boolean] true if token is blacklisted
  def self.blacklisted?(token)
    return false if token.blank?

    key = "blacklist:token:#{token}"
    redis.exists?(key) == 1
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.blacklisted? failed: #{e.message}")
    # Fail secure: if Redis is down, don't allow the token
    true
  end

  # Remove a token from the blacklist (rarely needed)
  # @param token [String] The JWT token to remove
  # @return [Boolean] true if successfully removed
  def self.remove(token)
    return false if token.blank?

    key = "blacklist:token:#{token}"
    redis.del(key) > 0
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.remove failed: #{e.message}")
    false
  end

  # Blacklist all tokens for a specific user
  # Useful when user changes password or is banned
  # @param user_id [String] The user ID
  # @param duration [Integer] Duration in seconds (default: 24 hours)
  # @return [Boolean] true if successfully added
  def self.blacklist_user(user_id, duration: 86400)
    return false if user_id.blank?

    key = "blacklist:user:#{user_id}"
    redis.setex(key, duration, '1')
    true
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.blacklist_user failed: #{e.message}")
    false
  end

  # Check if all tokens for a user are blacklisted
  # @param user_id [String] The user ID
  # @return [Boolean] true if user is blacklisted
  def self.user_blacklisted?(user_id)
    return false if user_id.blank?

    key = "blacklist:user:#{user_id}"
    redis.exists?(key) == 1
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.user_blacklisted? failed: #{e.message}")
    true  # Fail secure
  end

  # Remove user from blacklist
  # @param user_id [String] The user ID
  # @return [Boolean] true if successfully removed
  def self.unblacklist_user(user_id)
    return false if user_id.blank?

    key = "blacklist:user:#{user_id}"
    redis.del(key) > 0
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.unblacklist_user failed: #{e.message}")
    false
  end

  # Get count of blacklisted tokens
  # @return [Integer] Number of blacklisted tokens
  def self.count
    keys = redis.keys('blacklist:token:*')
    keys.size
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.count failed: #{e.message}")
    0
  end

  # Clear all blacklisted tokens (use with caution!)
  # @return [Boolean] true if successfully cleared
  def self.clear_all
    keys = redis.keys('blacklist:*')
    return true if keys.empty?

    redis.del(*keys) > 0
  rescue Redis::BaseError => e
    Rails.logger.error("TokenBlacklist.clear_all failed: #{e.message}")
    false
  end

  private

  # Extract TTL (time to live) from JWT token
  # @param token [String] The JWT token
  # @return [Integer, nil] TTL in seconds or nil if expired
  def self.extract_ttl(token)
    decoded = JWT.decode(token, JsonWebToken::SECRET_KEY, true, algorithm: 'HS256')[0]
    exp = decoded['exp']

    return nil unless exp

    ttl = exp - Time.now.to_i
    ttl > 0 ? ttl : nil
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
