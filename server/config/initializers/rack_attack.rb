# Configure Rack::Attack for rate limiting and throttling
# Documentation: https://github.com/rack/rack-attack

class Rack::Attack
  # Use Redis for distributed rate limiting across multiple servers
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    namespace: 'rack_attack'
  )

  # Allow localhost and private IPs in development
  safelist('allow-localhost') do |req|
    Rails.env.development? && ['127.0.0.1', '::1'].include?(req.ip)
  end

  # Safelist specific IPs (monitoring, health checks, etc.)
  # Add your monitoring service IPs here
  # safelist_ip('1.2.3.4')

  # Block requests from specific IPs
  # blocklist_ip('1.2.3.4')

  # Block requests with suspicious patterns
  blocklist('block-sql-injection') do |req|
    # Match SQL injection patterns
    Rack::Attack::Match.new(
      req.params.values.any? { |v| v.to_s =~ /union.*select|insert.*into|drop.*table/i }
    )
  end

  # ============================================================================
  # THROTTLING RULES
  # ============================================================================

  # Throttle authentication endpoints (more restrictive)
  # Limit to 5 requests per minute per IP
  throttle('auth/login', limit: 5, period: 1.minute) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.ip
    end
  end

  # Throttle registration endpoint
  # Limit to 3 requests per hour per IP
  throttle('auth/register', limit: 3, period: 1.hour) do |req|
    if req.path == '/api/v1/auth/register' && req.post?
      req.ip
    end
  end

  # Throttle password reset (when implemented)
  # Limit to 5 requests per hour per IP
  throttle('auth/password-reset', limit: 5, period: 1.hour) do |req|
    if req.path == '/api/v1/auth/forgot-password' && req.post?
      req.ip
    end
  end

  # Throttle general API requests for unauthenticated users
  # Limit to 100 requests per hour per IP
  throttle('api/unauthenticated', limit: 100, period: 1.hour) do |req|
    if req.path.start_with?('/api/') && !authenticated?(req)
      req.ip
    end
  end

  # Throttle general API requests for authenticated users
  # Limit to 1000 requests per hour per user
  throttle('api/authenticated', limit: 1000, period: 1.hour) do |req|
    if req.path.start_with?('/api/')
      user_id = authenticated?(req)
      user_id if user_id
    end
  end

  # Throttle search endpoints (more expensive operations)
  # Limit to 60 requests per minute per user
  throttle('api/search', limit: 60, period: 1.minute) do |req|
    if req.path.include?('/search') && req.get?
      authenticated?(req) || req.ip
    end
  end

  # Throttle file uploads (when implemented)
  # Limit to 20 uploads per hour per user
  throttle('api/uploads', limit: 20, period: 1.hour) do |req|
    if req.post? && (req.path.include?('/meals') || req.path.include?('/foods')) &&
       req.content_type&.start_with?('multipart/form-data')
      authenticated?(req) || req.ip
    end
  end

  # ============================================================================
  # RESPONSE CONFIGURATION
  # ============================================================================

  # Customize response when throttle limit is exceeded
  self.throttled_responder = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = Time.now.to_i
    period = match_data[:period]
    limit = match_data[:limit]

    # Calculate when the limit will reset
    reset_time = (now + (period - (now % period)))

    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => limit.to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => reset_time.to_s,
      'Retry-After' => (reset_time - now).to_s
    }

    body = {
      error: 'Rate limit exceeded',
      message: 'Too many requests. Please try again later.',
      retryAfter: reset_time
    }.to_json

    [429, headers, [body]]
  end

  # Customize response for blocklisted requests
  self.blocklisted_responder = lambda do |env|
    [403, { 'Content-Type' => 'application/json' }, [{
      error: 'Forbidden',
      message: 'Your request has been blocked'
    }.to_json]]
  end

  # ============================================================================
  # EXPONENTIAL BACKOFF (Ban repeat offenders)
  # ============================================================================

  # Ban IPs that exceed rate limits too many times
  # If an IP hits the limit 5 times in 1 hour, ban for 24 hours
  Rack::Attack.blocklist('repeat-offender-ban') do |req|
    # Count the number of times this IP has been throttled
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 5, findtime: 1.hour, bantime: 24.hours) do
      # Return true if the request was throttled
      req.env['rack.attack.matched']
    end
  end

  # ============================================================================
  # MONITORING AND LOGGING
  # ============================================================================

  # Track throttle events
  ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn(
      "[Rack::Attack] Throttled: #{req.ip} - Path: #{req.path} - " \
      "Matched: #{req.env['rack.attack.matched']} - " \
      "Match type: #{req.env['rack.attack.match_type']} - " \
      "Discriminator: #{req.env['rack.attack.match_discriminator']}"
    )
  end

  # Track blocklist events
  ActiveSupport::Notifications.subscribe('blocklist.rack_attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.error(
      "[Rack::Attack] Blocklisted: #{req.ip} - Path: #{req.path} - " \
      "Matched: #{req.env['rack.attack.matched']}"
    )
  end

  private

  # Helper method to check if request is authenticated
  # Returns user_id if authenticated, nil otherwise
  def self.authenticated?(req)
    return nil unless req.env['HTTP_AUTHORIZATION']

    token = req.env['HTTP_AUTHORIZATION'].split(' ').last
    return nil unless token

    begin
      decoded = JWT.decode(token, JsonWebToken::SECRET_KEY)[0]
      decoded['user_id']
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end
  rescue StandardError
    nil
  end
end
