module ProductionErrorHandling
  extend ActiveSupport::Concern

  included do
    # Enhanced error handling for production
    rescue_from StandardError, with: :handle_production_error if Rails.env.production?
  end

  private

  def handle_production_error(exception)
    # Log comprehensive error information
    Rails.logger.error "Production Error: #{exception.class.name}"
    Rails.logger.error "Message: #{exception.message}"
    Rails.logger.error "User: #{current_user&.id || 'anonymous'}"
    Rails.logger.error "Path: #{request.path}"
    Rails.logger.error "Method: #{request.method}"
    Rails.logger.error "Params: #{params.except(:password, :password_confirmation).inspect}"
    Rails.logger.error "User Agent: #{request.user_agent}"
    Rails.logger.error "IP: #{request.remote_ip}"
    Rails.logger.error "Backtrace: #{exception.backtrace.first(15).join('\n')}"

    # Determine response based on request type
    respond_to do |format|
      format.html do
        if exception.is_a?(ActiveRecord::RecordNotFound)
          render_404
        else
          render_500
        end
      end

      format.json do
        error_response = {
          error: 'Internal server error',
          message: 'An error occurred while processing your request',
          timestamp: Time.current.iso8601,
          request_id: request.uuid
        }

        # Add debug info in development
        if Rails.env.development?
          error_response[:debug] = {
            error_class: exception.class.name,
            error_message: exception.message,
            backtrace: exception.backtrace.first(5)
          }
        end

        render json: error_response, status: :internal_server_error
      end
    end
  end

  def log_authentication_issue(issue_type, details = {})
    Rails.logger.warn "Authentication Issue: #{issue_type}"
    Rails.logger.warn "Details: #{details.inspect}"
    Rails.logger.warn "User: #{current_user&.id || 'anonymous'}"
    Rails.logger.warn "Session ID: #{session.id}"
    Rails.logger.warn "Path: #{request.path}"
    Rails.logger.warn "User Agent: #{request.user_agent}"
  end

  def log_dashboard_performance(start_time, component, details = {})
    duration = ((Time.current - start_time) * 1000).round(2)
    Rails.logger.info "Dashboard Performance: #{component} took #{duration}ms"
    Rails.logger.info "Details: #{details.inspect}" if details.any?
  end
end