class AnalyticsEvent < ApplicationRecord
  belongs_to :user, optional: true

  enum :event_type, {
    page_view: 0,
    wishlist_created: 1,
    item_added: 2,
    invitation_sent: 3,
    connection_formed: 4,
    item_purchased: 5,
    wishlist_shared: 6,
    login_attempt: 7,
    sign_up_attempt: 8,
    invitation_accepted: 9,
    notification_clicked: 10,
    search_performed: 11,
    error_occurred: 12,
    consent_given: 13
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_event_type, ->(type) { where(event_type: type) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }

  # Validations
  validates :event_type, presence: true
  validates :session_id, presence: true

  # Class methods
  def self.track(event_type, user: nil, session_id: nil, request: nil, **metadata)
    create!(
      user: user,
      event_type: event_type,
      session_id: session_id,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent,
      page_path: request&.path,
      page_title: metadata.delete(:page_title),
      referrer: request&.referer,
      metadata: metadata.presence
    )
  end

  # Instance methods
  def anonymous?
    user_id.nil?
  end

  def metadata_json
    metadata.is_a?(String) ? JSON.parse(metadata) : metadata
  rescue JSON::ParserError
    {}
  end
end
