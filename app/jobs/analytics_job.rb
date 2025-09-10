class AnalyticsJob < ApplicationJob
  queue_as :analytics
  
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(event_type, user_id = nil, session_id = nil, request_data = {}, **metadata)
    user = user_id ? User.find_by(id: user_id) : nil
    
    # Create the analytics event
    event = AnalyticsEvent.create!(
      user: user,
      event_type: event_type,
      session_id: session_id,
      ip_address: request_data[:remote_ip],
      user_agent: request_data[:user_agent],
      page_path: request_data[:path],
      page_title: metadata[:page_title],
      referrer: request_data[:referer],
      metadata: metadata.except(:page_title).presence
    )
    
    # Update user analytics aggregates if user exists
    if user
      update_user_analytics(user, event_type, metadata)
    end
    
    Rails.logger.info "Analytics event tracked: #{event_type} for user #{user_id || 'anonymous'}"
    event
  end
  
  private
  
  def update_user_analytics(user, event_type, metadata)
    analytics = UserAnalytic.find_or_create_for_user(user)
    
    case event_type.to_s
    when 'wishlist_created'
      analytics.increment_wishlists_created!
    when 'item_added'
      analytics.increment_items_added!
    when 'connection_formed'
      analytics.increment_connections!
    when 'invitation_sent'
      analytics.increment_invitations_sent!
    when 'invitation_accepted'
      analytics.increment_invitations_accepted!
    when 'item_purchased'
      analytics.increment_items_purchased!
    when 'page_view'
      analytics.increment_page_views!
    end
  rescue => e
    Rails.logger.error "Failed to update user analytics: #{e.message}"
    # Don't fail the job for analytics updates
  end
end
