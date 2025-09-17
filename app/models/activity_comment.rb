class ActivityComment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, class_name: 'ActivityComment', optional: true
  has_many :replies, class_name: 'ActivityComment', foreign_key: 'parent_id', dependent: :destroy

  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :replies_to, ->(comment) { where(parent: comment) }

  # Instance methods
  def reply?
    parent_id.present?
  end

  def top_level?
    parent_id.nil?
  end

  def replies_count
    replies.count
  end

  def depth
    return 0 if top_level?
    1 + (parent&.depth || 0)
  end

  # Get the root comment in a thread
  def root_comment
    return self if top_level?
    parent&.root_comment || self
  end

  # Class methods
  def self.create_comment(user:, commentable:, content:, parent: nil)
    create!(
      user: user,
      commentable: commentable,
      content: content,
      parent: parent
    )
  end

  # Commentable interface methods (for consistent API)
  def commentable_name
    case commentable_type
    when 'Wishlist'
      commentable.name
    when 'WishlistItem'
      commentable.name
    when 'ActivityFeed'
      commentable.action_description
    else
      commentable_type
    end
  end
end