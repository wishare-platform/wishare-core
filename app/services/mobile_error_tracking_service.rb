# Mobile Error Tracking Service for Wishare
# Comprehensive error handling and crash reporting for mobile apps
class MobileErrorTrackingService
  include ActiveSupport::Benchmarkable

  # Error severity levels
  SEVERITY_LEVELS = {
    info: 0,
    warning: 1,
    error: 2,
    fatal: 3
  }.freeze

  # Error categories
  ERROR_CATEGORIES = {
    api: 'API Error',
    network: 'Network Error',
    authentication: 'Authentication Error',
    database: 'Database Error',
    cache: 'Cache Error',
    external_service: 'External Service Error',
    performance: 'Performance Error',
    user_input: 'User Input Error',
    ui: 'UI Error',
    background_job: 'Background Job Error'
  }.freeze

  class << self
    # Main error tracking method
    def track_error(error_data, context = {})
      benchmark "Mobile Error Tracking" do
        # Sanitize and structure error data
        structured_error = structure_error_data(error_data, context)

        # Store in database
        mobile_error = create_mobile_error_record(structured_error)

        # Send to external services (if configured)
        send_to_external_services(structured_error) if should_send_to_external?

        # Send alerts for critical errors
        send_alert_if_critical(structured_error)

        # Update error metrics
        update_error_metrics(structured_error)

        mobile_error
      end
    rescue => e
      Rails.logger.error "❌ Error tracking failed: #{e.message}"
      nil
    end

    # Track mobile-specific performance issues
    def track_performance_issue(issue_data, context = {})
      performance_data = {
        error_type: 'performance_issue',
        category: 'performance',
        severity: determine_performance_severity(issue_data),
        message: build_performance_message(issue_data),
        metadata: issue_data.merge(context),
        platform: context[:platform] || 'unknown',
        app_version: context[:app_version] || 'unknown'
      }

      track_error(performance_data, context)
    end

    # Track API errors with mobile context
    def track_api_error(request, response, context = {})
      api_error_data = {
        error_type: 'api_error',
        category: 'api',
        severity: determine_api_error_severity(response),
        message: "API Error: #{response[:status]} - #{request[:endpoint]}",
        metadata: {
          request: sanitize_request_data(request),
          response: sanitize_response_data(response),
          endpoint: request[:endpoint],
          method: request[:method],
          status_code: response[:status]
        }.merge(context)
      }

      track_error(api_error_data, context)
    end

    # Track network connectivity issues
    def track_network_error(network_data, context = {})
      network_error_data = {
        error_type: 'network_error',
        category: 'network',
        severity: determine_network_severity(network_data),
        message: "Network Error: #{network_data[:error_type]}",
        metadata: network_data.merge(context)
      }

      track_error(network_error_data, context)
    end

    # Get error analytics for dashboard
    def get_error_analytics(timeframe: 7.days, platform: nil)
      errors = MobileError.where(created_at: timeframe.ago..Time.current)
      errors = errors.where(platform: platform) if platform.present?

      {
        total_errors: errors.count,
        errors_by_severity: errors.group(:severity).count,
        errors_by_category: errors.group(:category).count,
        errors_by_platform: errors.group(:platform).count,
        errors_by_app_version: errors.group(:app_version).count,
        top_errors: errors.group(:fingerprint).count.sort_by(&:last).last(10),
        error_trend: errors.group_by_day(:created_at).count,
        crash_rate: calculate_crash_rate(errors, timeframe),
        affected_users: errors.distinct.count(:user_id)
      }
    end

    # Get error details for debugging
    def get_error_details(error_id)
      error = MobileError.find(error_id)

      {
        error: error,
        similar_errors: find_similar_errors(error),
        user_context: get_user_context(error.user_id),
        device_context: error.device_info,
        occurrence_pattern: analyze_occurrence_pattern(error)
      }
    end

    private

    def structure_error_data(error_data, context)
      {
        error_type: error_data[:error_type] || 'unknown',
        category: error_data[:category] || 'unknown',
        severity: normalize_severity(error_data[:severity]),
        message: error_data[:message] || 'Unknown error',
        stack_trace: sanitize_stack_trace(error_data[:stack_trace]),
        fingerprint: generate_error_fingerprint(error_data),
        metadata: (error_data[:metadata] || {}).merge(context),
        platform: context[:platform] || extract_platform(context),
        app_version: context[:app_version] || 'unknown',
        os_version: context[:os_version] || 'unknown',
        device_model: context[:device_model] || 'unknown',
        user_id: context[:user_id],
        session_id: context[:session_id],
        request_id: context[:request_id],
        timestamp: Time.current,
        environment: Rails.env,
        server_version: get_server_version,
        device_info: extract_device_info(context),
        network_info: extract_network_info(context),
        memory_info: extract_memory_info(context)
      }
    end

    def create_mobile_error_record(error_data)
      MobileError.create!(
        error_type: error_data[:error_type],
        category: error_data[:category],
        severity: error_data[:severity],
        message: error_data[:message],
        stack_trace: error_data[:stack_trace],
        fingerprint: error_data[:fingerprint],
        metadata: error_data[:metadata],
        platform: error_data[:platform],
        app_version: error_data[:app_version],
        os_version: error_data[:os_version],
        device_model: error_data[:device_model],
        user_id: error_data[:user_id],
        session_id: error_data[:session_id],
        request_id: error_data[:request_id],
        environment: error_data[:environment],
        server_version: error_data[:server_version],
        device_info: error_data[:device_info],
        network_info: error_data[:network_info],
        memory_info: error_data[:memory_info],
        resolved: false,
        first_seen: Time.current,
        last_seen: Time.current,
        occurrence_count: 1
      )
    rescue ActiveRecord::RecordNotUnique
      # Error already exists, update occurrence count
      existing_error = MobileError.find_by(fingerprint: error_data[:fingerprint])
      existing_error&.increment!(:occurrence_count)
      existing_error&.update!(last_seen: Time.current)
      existing_error
    end

    def generate_error_fingerprint(error_data)
      fingerprint_data = [
        error_data[:error_type],
        error_data[:category],
        clean_message_for_fingerprint(error_data[:message]),
        extract_key_stack_frames(error_data[:stack_trace])
      ].compact.join('|')

      Digest::SHA256.hexdigest(fingerprint_data)[0..15] # 16 character fingerprint
    end

    def clean_message_for_fingerprint(message)
      return nil unless message

      # Remove variable data like IDs, timestamps, etc.
      message.gsub(/\d+/, 'X')
             .gsub(/[a-f0-9]{8,}/, 'HASH')
             .gsub(/\b\w+@\w+\.\w+\b/, 'EMAIL')
             .strip
    end

    def extract_key_stack_frames(stack_trace)
      return nil unless stack_trace.is_a?(Array)

      # Take first 3 meaningful stack frames
      stack_trace.first(3).map do |frame|
        frame[:function] || frame[:method] || 'unknown'
      end.join('>')
    end

    def determine_performance_severity(issue_data)
      response_time = issue_data[:response_time_ms]&.to_f || 0
      memory_usage = issue_data[:memory_usage_mb]&.to_f || 0

      case
      when response_time > 5000 || memory_usage > 200
        'fatal'
      when response_time > 2000 || memory_usage > 150
        'error'
      when response_time > 1000 || memory_usage > 100
        'warning'
      else
        'info'
      end
    end

    def determine_api_error_severity(response)
      status = response[:status]&.to_i || 0

      case status
      when 500..599
        'fatal'
      when 400..499
        'error'
      when 300..399
        'warning'
      else
        'info'
      end
    end

    def determine_network_severity(network_data)
      error_type = network_data[:error_type]

      case error_type&.downcase
      when /timeout|connection/
        'error'
      when /slow|degraded/
        'warning'
      when /offline|unreachable/
        'fatal'
      else
        'info'
      end
    end

    def build_performance_message(issue_data)
      components = []
      components << "Response time: #{issue_data[:response_time_ms]}ms" if issue_data[:response_time_ms]
      components << "Memory usage: #{issue_data[:memory_usage_mb]}MB" if issue_data[:memory_usage_mb]
      components << "CPU usage: #{issue_data[:cpu_usage_percent]}%" if issue_data[:cpu_usage_percent]

      "Performance Issue: #{components.join(', ')}"
    end

    def normalize_severity(severity)
      severity = severity.to_s.downcase
      SEVERITY_LEVELS.key?(severity.to_sym) ? severity : 'error'
    end

    def sanitize_stack_trace(stack_trace)
      return nil unless stack_trace

      case stack_trace
      when String
        parse_stack_trace_string(stack_trace)
      when Array
        stack_trace.map { |frame| sanitize_stack_frame(frame) }
      else
        nil
      end
    end

    def parse_stack_trace_string(stack_string)
      stack_string.split("\n").first(20).map do |line|
        # Parse common stack trace formats
        if line.match(/(.+):(\d+):(\d+)/)
          {
            file: $1,
            line: $2.to_i,
            column: $3.to_i,
            function: extract_function_from_line(line)
          }
        else
          { raw: line.strip }
        end
      end
    end

    def sanitize_stack_frame(frame)
      return frame unless frame.is_a?(Hash)

      {
        file: frame[:file] || frame['file'],
        line: frame[:line] || frame['line'],
        column: frame[:column] || frame['column'],
        function: frame[:function] || frame['function'] || frame[:method] || frame['method'],
        context: frame[:context] || frame['context']
      }.compact
    end

    def extract_function_from_line(line)
      # Extract function name from various stack trace formats
      if line.match(/at\s+(.+?)\s+\(/)
        $1
      elsif line.match(/in\s+(.+?)$/)
        $1
      else
        nil
      end
    end

    def sanitize_request_data(request)
      return {} unless request.is_a?(Hash)

      {
        endpoint: request[:endpoint],
        method: request[:method],
        headers: sanitize_headers(request[:headers]),
        query_params: request[:query_params],
        body_size: request[:body]&.length
      }.compact
    end

    def sanitize_response_data(response)
      return {} unless response.is_a?(Hash)

      {
        status: response[:status],
        headers: sanitize_headers(response[:headers]),
        body_size: response[:body]&.length,
        response_time_ms: response[:response_time_ms]
      }.compact
    end

    def sanitize_headers(headers)
      return {} unless headers.is_a?(Hash)

      sensitive_headers = %w[authorization cookie session token api-key x-api-key]

      headers.transform_keys(&:downcase).except(*sensitive_headers)
    end

    def extract_platform(context)
      user_agent = context[:user_agent] || context['User-Agent'] || ''

      case user_agent.downcase
      when /iphone|ipad|ios/
        'ios'
      when /android/
        'android'
      else
        'unknown'
      end
    end

    def extract_device_info(context)
      {
        model: context[:device_model],
        os_version: context[:os_version],
        app_version: context[:app_version],
        screen_size: context[:screen_size],
        orientation: context[:orientation],
        battery_level: context[:battery_level],
        storage_available: context[:storage_available]
      }.compact
    end

    def extract_network_info(context)
      {
        connection_type: context[:connection_type],
        network_strength: context[:network_strength],
        carrier: context[:carrier],
        wifi_connected: context[:wifi_connected]
      }.compact
    end

    def extract_memory_info(context)
      {
        used_memory_mb: context[:used_memory_mb],
        available_memory_mb: context[:available_memory_mb],
        memory_pressure: context[:memory_pressure]
      }.compact
    end

    def get_server_version
      # Return current server/API version
      Rails.application.config.version || 'unknown'
    end

    def should_send_to_external?
      # Only send to external services in production
      Rails.env.production? && (ENV['SENTRY_DSN'].present? || ENV['BUGSNAG_API_KEY'].present?)
    end

    def send_to_external_services(error_data)
      # Send to Sentry if configured
      send_to_sentry(error_data) if ENV['SENTRY_DSN'].present?

      # Send to Bugsnag if configured
      send_to_bugsnag(error_data) if ENV['BUGSNAG_API_KEY'].present?
    end

    def send_to_sentry(error_data)
      # Implementation for Sentry integration
      Rails.logger.info "📤 Sending error to Sentry: #{error_data[:fingerprint]}"
    end

    def send_to_bugsnag(error_data)
      # Implementation for Bugsnag integration
      Rails.logger.info "📤 Sending error to Bugsnag: #{error_data[:fingerprint]}"
    end

    def send_alert_if_critical(error_data)
      return unless error_data[:severity] == 'fatal'

      # Send Slack alert for critical errors
      SlackNotificationService.send_alert(
        channel: '#mobile-alerts',
        message: "🚨 Critical mobile error: #{error_data[:message]}",
        details: {
          platform: error_data[:platform],
          app_version: error_data[:app_version],
          affected_users: 1,
          fingerprint: error_data[:fingerprint]
        }
      )
    end

    def update_error_metrics(error_data)
      # Update Redis counters for real-time metrics
      Redis.current.pipelined do |pipeline|
        date_key = Date.current.strftime('%Y-%m-%d')

        pipeline.incr("mobile_errors:total:#{date_key}")
        pipeline.incr("mobile_errors:#{error_data[:platform]}:#{date_key}")
        pipeline.incr("mobile_errors:#{error_data[:severity]}:#{date_key}")
        pipeline.incr("mobile_errors:#{error_data[:category]}:#{date_key}")

        # Set expiration for metrics (30 days)
        pipeline.expire("mobile_errors:total:#{date_key}", 30.days.to_i)
        pipeline.expire("mobile_errors:#{error_data[:platform]}:#{date_key}", 30.days.to_i)
        pipeline.expire("mobile_errors:#{error_data[:severity]}:#{date_key}", 30.days.to_i)
        pipeline.expire("mobile_errors:#{error_data[:category]}:#{date_key}", 30.days.to_i)
      end
    rescue Redis::BaseError => e
      Rails.logger.warn "⚠️ Failed to update error metrics: #{e.message}"
    end

    def calculate_crash_rate(errors, timeframe)
      fatal_errors = errors.where(severity: 'fatal')
      total_sessions = get_total_sessions(timeframe)

      return 0.0 if total_sessions.zero?

      (fatal_errors.count.to_f / total_sessions * 100).round(2)
    end

    def get_total_sessions(timeframe)
      # This would be tracked separately, returning placeholder
      1000
    end

    def find_similar_errors(error)
      MobileError.where(fingerprint: error.fingerprint)
                 .where.not(id: error.id)
                 .order(created_at: :desc)
                 .limit(10)
    end

    def get_user_context(user_id)
      return {} unless user_id

      user = User.find_by(id: user_id)
      return {} unless user

      {
        user_id: user.id,
        email: user.email,
        created_at: user.created_at,
        wishlists_count: user.wishlists_count,
        connections_count: user.connections_count,
        last_sign_in_at: user.current_sign_in_at
      }
    end

    def analyze_occurrence_pattern(error)
      occurrences = MobileError.where(fingerprint: error.fingerprint)
                              .order(:created_at)
                              .pluck(:created_at)

      {
        first_occurrence: occurrences.first,
        last_occurrence: occurrences.last,
        total_occurrences: occurrences.count,
        occurrences_last_24h: occurrences.count { |time| time > 24.hours.ago },
        occurrences_last_week: occurrences.count { |time| time > 1.week.ago },
        pattern: detect_occurrence_pattern(occurrences)
      }
    end

    def detect_occurrence_pattern(occurrences)
      return 'isolated' if occurrences.count < 3

      time_diffs = occurrences.each_cons(2).map { |a, b| b - a }
      avg_interval = time_diffs.sum / time_diffs.count

      case avg_interval
      when 0..1.minute
        'burst'
      when 1.minute..1.hour
        'frequent'
      when 1.hour..1.day
        'periodic'
      else
        'sporadic'
      end
    end
  end
end