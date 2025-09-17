class UserInteraction < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true

  # Validations
  validates :interaction_type, presence: true
  validates :user_id, uniqueness: { scope: [:target_type, :target_id] }

  # Interaction types enum-like constants
  INTERACTION_TYPES = %w[
    like
    save
    view
    share
    bookmark
  ].freeze

  validates :interaction_type, inclusion: { in: INTERACTION_TYPES }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(interaction_type: type) }
  scope :likes, -> { where(interaction_type: 'like') }
  scope :saves, -> { where(interaction_type: 'save') }
  scope :views, -> { where(interaction_type: 'view') }
  scope :shares, -> { where(interaction_type: 'share') }
  scope :bookmarks, -> { where(interaction_type: 'bookmark') }

  # Class methods
  def self.like!(user, target)
    find_or_create_by(user: user, target: target, interaction_type: 'like')
  end

  def self.unlike!(user, target)
    where(user: user, target: target, interaction_type: 'like').destroy_all
  end

  def self.save!(user, target)
    find_or_create_by(user: user, target: target, interaction_type: 'save')
  end

  def self.unsave!(user, target)
    where(user: user, target: target, interaction_type: 'save').destroy_all
  end

  def self.record_view!(user, target)
    # For views, we might want to update the timestamp rather than create duplicates
    interaction = find_or_initialize_by(user: user, target: target, interaction_type: 'view')
    interaction.touch
    interaction
  end

  def self.record_share!(user, target)
    create!(user: user, target: target, interaction_type: 'share')
  end

  def self.bookmark!(user, target)
    find_or_create_by(user: user, target: target, interaction_type: 'bookmark')
  end

  def self.unbookmark!(user, target)
    where(user: user, target: target, interaction_type: 'bookmark').destroy_all
  end

  # Instance methods
  def like?
    interaction_type == 'like'
  end

  def save?
    interaction_type == 'save'
  end

  def view?
    interaction_type == 'view'
  end

  def share?
    interaction_type == 'share'
  end

  def bookmark?
    interaction_type == 'bookmark'
  end
end