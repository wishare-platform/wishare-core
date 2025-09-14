# frozen_string_literal: true

class JwtCleanupJob < ApplicationJob
  queue_as :default

  def perform
    # Clean up expired JWT tokens from denylist
    expired_count = JwtDenylist.cleanup_expired!
    Rails.logger.info "JWT Cleanup: Removed #{expired_count} expired tokens"
  end
end