class ActivityFeed < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User'
  belongs_to :target, polymorphic: true

  # Validations
  validates :action_type, presence: true
  validates :occurred_at, presence: true

  # Scopes
  scope :recent, -> { order(occurred_at: :desc) }
  scope :public_activities, -> { where(is_public: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :by_actor, ->(actor) { where(actor: actor) }
  scope :by_action_type, ->(action_type) { where(action_type: action_type) }
  scope :today, -> { where(occurred_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(occurred_at: 1.week.ago..Time.current) }

  # Action types enum-like constants
  ACTION_TYPES = %w[
    wishlist_created
    item_added
    item_purchased
    wishlist_liked
    wishlist_commented
    item_commented
    friend_connected
    profile_updated
    wishlist_shared
  ].freeze

  # Validation for action types
  validates :action_type, inclusion: { in: ACTION_TYPES }

  # Class methods
  def self.create_activity(action_type:, actor:, target:, user: nil, metadata: {}, is_public: true)
    create!(
      action_type: action_type,
      actor: actor,
      target: target,
      user: user || actor,
      metadata: metadata,
      is_public: is_public,
      occurred_at: Time.current
    )
  end

  # Instance methods
  def metadata_json
    metadata.is_a?(String) ? JSON.parse(metadata) : metadata
  rescue JSON::ParserError
    {}
  end

  def target_name
    case target_type
    when 'Wishlist'
      target.name
    when 'WishlistItem'
      target.name
    when 'User'
      target.name
    else
      target_type
    end
  end

  def action_description
    case action_type
    when 'wishlist_created'
      "created a new wishlist"
    when 'item_added'
      "added an item"
    when 'item_purchased'
      "purchased an item"
    when 'wishlist_liked'
      "liked a wishlist"
    when 'wishlist_commented'
      "commented on a wishlist"
    when 'item_commented'
      "commented on an item"
    when 'friend_connected'
      "connected with a friend"
    when 'profile_updated'
      "updated their profile"
    when 'wishlist_shared'
      "shared a wishlist"
    else
      action_type.humanize
    end
  end
end