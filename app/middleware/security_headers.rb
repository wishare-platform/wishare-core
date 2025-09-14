class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Security Headers
    headers['X-Frame-Options'] = 'DENY'
    headers['X-Content-Type-Options'] = 'nosniff'
    headers['X-XSS-Protection'] = '1; mode=block'
    headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    headers['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'

    # Content Security Policy
    headers['Content-Security-Policy'] = csp_policy(env)

    # Strict Transport Security (only for production)
    if Rails.env.production?
      headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains; preload'
    end

    [status, headers, response]
  end

  private

  def csp_policy(env)
    # Build CSP policy based on environment
    directives = []

    # Default source
    directives << "default-src 'self'"

    # Script sources
    script_src = "'self' 'unsafe-inline'"
    script_src += " https://www.googletagmanager.com https://www.google-analytics.com"
    script_src += " 'unsafe-eval'" if Rails.env.development? # For Rails development
    directives << "script-src #{script_src}"

    # Style sources
    style_src = "'self' 'unsafe-inline'"
    style_src += " https://fonts.googleapis.com"
    directives << "style-src #{style_src}"

    # Image sources
    img_src = "'self' data: blob: https:"
    directives << "img-src #{img_src}"

    # Font sources
    font_src = "'self' data:"
    font_src += " https://fonts.gstatic.com"
    directives << "font-src #{font_src}"

    # Connect sources (for AJAX, WebSocket, etc.)
    connect_src = "'self'"
    connect_src += " wss: ws:" if Rails.env.development?
    connect_src += " https://www.google-analytics.com https://analytics.google.com" if Rails.env.production?
    directives << "connect-src #{connect_src}"

    # Frame sources (for OAuth)
    frame_src = "'self'"
    frame_src += " https://accounts.google.com" # For Google OAuth
    directives << "frame-src #{frame_src}"

    # Form action (allow Google OAuth)
    form_action = "'self'"
    form_action += " https://accounts.google.com"
    directives << "form-action #{form_action}"

    # Base URI
    directives << "base-uri 'self'"

    # Object source (Flash, etc.)
    directives << "object-src 'none'"

    # Media sources
    directives << "media-src 'self'"

    # Child sources
    directives << "child-src 'self'"

    # Worker sources
    directives << "worker-src 'self' blob:"

    # Manifest source
    directives << "manifest-src 'self'"

    # Upgrade insecure requests in production
    directives << "upgrade-insecure-requests" if Rails.env.production?

    directives.join('; ')
  end
end