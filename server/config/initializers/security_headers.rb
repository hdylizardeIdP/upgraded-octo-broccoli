# Security Headers Middleware
# Implements best practices for web application security headers
# References:
# - OWASP Secure Headers Project: https://owasp.org/www-project-secure-headers/
# - Mozilla Observatory: https://observatory.mozilla.org/

class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Prevent clickjacking attacks
    # DENY: Page cannot be displayed in a frame, regardless of the site attempting to do so
    headers['X-Frame-Options'] = 'DENY'

    # Prevent MIME type sniffing
    # Browsers will not try to detect the content type if it's not explicitly set
    headers['X-Content-Type-Options'] = 'nosniff'

    # Enable XSS protection in browsers (legacy, but still useful for older browsers)
    # 1; mode=block: Enable XSS filter and block the page if an attack is detected
    headers['X-XSS-Protection'] = '1; mode=block'

    # Control how much referrer information should be included with requests
    # strict-origin-when-cross-origin: Send full URL on same-origin, only origin on cross-origin HTTPS
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'

    # Prevent the browser from caching sensitive information
    # For API responses, we want to prevent caching of user-specific data
    headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, private'
    headers['Pragma'] = 'no-cache'
    headers['Expires'] = '0'

    # Content Security Policy (CSP)
    # Helps prevent XSS, clickjacking, and other code injection attacks
    # For an API-only application, we're very restrictive
    headers['Content-Security-Policy'] = [
      "default-src 'none'",           # Block all content by default
      "script-src 'none'",            # No scripts allowed
      "style-src 'none'",             # No styles allowed
      "img-src 'none'",               # No images allowed
      "font-src 'none'",              # No fonts allowed
      "connect-src 'self'",           # Only allow connections to same origin
      "frame-ancestors 'none'",       # Don't allow this to be embedded in frames
      "base-uri 'none'",              # Prevent base tag injection
      "form-action 'none'"            # No forms allowed
    ].join('; ')

    # Permissions Policy (formerly Feature-Policy)
    # Control which browser features and APIs can be used
    # For an API, we disable all features
    headers['Permissions-Policy'] = [
      'accelerometer=()',
      'camera=()',
      'geolocation=()',
      'gyroscope=()',
      'magnetometer=()',
      'microphone=()',
      'payment=()',
      'usb=()',
      'interest-cohort=()'  # Disable FLoC tracking
    ].join(', ')

    # HTTP Strict Transport Security (HSTS)
    # Force HTTPS connections for this domain
    # Only enabled in production
    # max-age=31536000: Remember HSTS for 1 year
    # includeSubDomains: Apply to all subdomains
    # preload: Allow inclusion in browser preload lists
    if Rails.env.production?
      headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    end

    # X-Download-Options (IE specific)
    # Prevents IE from executing downloads in the context of the site
    headers['X-Download-Options'] = 'noopen'

    # X-Permitted-Cross-Domain-Policies
    # Restricts Adobe Flash and PDF cross-domain requests
    headers['X-Permitted-Cross-Domain-Policies'] = 'none'

    [status, headers, response]
  end
end

# Register the middleware
Rails.application.config.middleware.use SecurityHeaders
