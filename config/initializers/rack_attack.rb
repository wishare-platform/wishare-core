class Rack::Attack
  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Spammy Clients ###

  # Throttle all requests by IP (60rpm)
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  ### Prevent Brute-Force Login Attacks ###

  # Throttle POST requests to /users/sign_in by IP address
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/sign_in by email param
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      # Normalize the email, using the same logic as your authentication process, to
      # protect against rate limit bypasses.
      req.params['user']['email'].to_s.downcase.gsub(/\s+/, "") if req.params['user']
    end
  end

  ### Prevent Brute-Force Password Reset Attacks ###

  # Throttle POST requests to /users/password by IP address
  throttle('password_resets/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/password' && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/password by email param
  throttle('password_resets/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/password' && req.post?
      req.params['user']['email'].to_s.downcase.gsub(/\s+/, "") if req.params['user']
    end
  end

  ### Prevent Brute-Force Sign Up Attacks ###

  # Throttle POST requests to /users by IP address
  throttle('signups/ip', limit: 3, period: 15.minutes) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  ### API Rate Limiting ###

  # Throttle API requests by IP
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api/')
      req.ip
    end
  end

  # Throttle API requests by authenticated user (JWT)
  throttle('api/user', limit: 300, period: 1.minute) do |req|
    if req.path.start_with?('/api/') && req.env['HTTP_AUTHORIZATION']
      # Extract user ID from JWT token if present
      auth_header = req.env['HTTP_AUTHORIZATION']
      if auth_header&.start_with?('Bearer ')
        token = auth_header.split(' ').last
        begin
          payload = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256').first
          payload['sub'] # user_id
        rescue JWT::DecodeError
          nil
        end
      end
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  self.throttled_responder = lambda do |env|
    now = Time.now
    match_data = env['rack.attack.match_data']

    headers = {
      'Content-Type' => 'application/json',
      'Retry-After' => (match_data[:period] - (now.to_i % match_data[:period])).to_s,
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now.to_i % match_data[:period])).to_s
    }

    body = {
      error: 'Too Many Requests',
      message: 'You have exceeded the rate limit. Please try again later.',
      retry_after: headers['Retry-After']
    }.to_json

    [429, headers, [body]]
  end

  ### Block Suspicious Requests ###

  # Block requests from bad user agents
  Rack::Attack.blocklist('bad-user-agents') do |req|
    bad_agents = [
      'masscan',
      'nmap',
      'sqlmap',
      'nikto',
      'acunetix',
      'nessus',
      'metasploit'
    ]

    user_agent = req.user_agent.to_s.downcase
    bad_agents.any? { |agent| user_agent.include?(agent) }
  end

  # Block requests trying to access sensitive files
  Rack::Attack.blocklist('sensitive-files') do |req|
    sensitive_paths = [
      '.env',
      '.git',
      'wp-admin',
      'wp-login',
      'phpmyadmin',
      '.ssh',
      'config.php',
      'web.config'
    ]

    sensitive_paths.any? { |path| req.path.include?(path) }
  end

  ### Safelist ###

  # It's important to make sure legitimate users can still use your app
  # We recommend using a safelist for certain IP addresses or user agents

  # Safelist localhost and private network IPs (for development/testing)
  Rack::Attack.safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  # You can also safelist certain paths
  Rack::Attack.safelist('allow-health-check') do |req|
    req.path == '/health' || req.path == '/up'
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack