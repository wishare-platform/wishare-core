class UserAnalytic < ApplicationRecord
  belongs_to :user
  
  # Callbacks
  after_initialize :set_defaults
  
  # Class methods
  def self.find_or_create_for_user(user)
    find_or_create_by(user: user)
  end
  
  def self.update_for_user(user, metric, increment_by = 1)
    analytics = find_or_create_for_user(user)
    analytics.increment!(metric, increment_by)
    analytics.update!(last_activity_at: Time.current)
    analytics
  end
  
  # Instance methods
  def increment_wishlists_created!
    increment!(:wishlists_created_count)
    touch_activity!
  end
  
  def increment_items_added!
    increment!(:items_added_count)
    touch_activity!
  end
  
  def increment_connections!
    increment!(:connections_count)
    touch_activity!
  end
  
  def increment_invitations_sent!
    increment!(:invitations_sent_count)
    touch_activity!
  end
  
  def increment_invitations_accepted!
    increment!(:invitations_accepted_count)
    touch_activity!
  end
  
  def increment_items_purchased!
    increment!(:items_purchased_count)
    touch_activity!
  end
  
  def increment_page_views!
    increment!(:page_views_count)
    touch_activity!
  end
  
  def engagement_score
    # Calculate engagement based on activity
    base_score = [
      wishlists_created_count * 10,
      items_added_count * 5,
      connections_count * 15,
      invitations_sent_count * 8,
      invitations_accepted_count * 12,
      items_purchased_count * 20
    ].sum
    
    # Bonus for recent activity
    if last_activity_at && last_activity_at > 1.week.ago
      base_score * 1.2
    else
      base_score
    end
  end
  
  def active_user?
    last_activity_at && last_activity_at > 30.days.ago
  end
  
  def days_since_last_activity
    return nil unless last_activity_at
    (Time.current - last_activity_at) / 1.day
  end
  
  private
  
  def set_defaults
    if new_record?
      self.first_activity_at ||= Time.current
      self.last_activity_at ||= Time.current
    end
  end
  
  def touch_activity!
    update!(last_activity_at: Time.current)
    update!(first_activity_at: Time.current) if first_activity_at.nil?
  end
end
