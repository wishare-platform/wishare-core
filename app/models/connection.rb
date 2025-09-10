class Connection < ApplicationRecord
  belongs_to :user
  belongs_to :partner, class_name: "User"

  enum :status, { pending: 0, accepted: 1, declined: 2 }

  validates :user_id, uniqueness: { scope: :partner_id }
  validate :cannot_connect_to_self

  scope :accepted_connections, -> { where(status: :accepted) }

  def self.between_users(user1, user2)
    where(
      "(user_id = ? AND partner_id = ?) OR (user_id = ? AND partner_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).first
  end

  def other_user(current_user)
    current_user == user ? partner : user
  end

  private

  def cannot_connect_to_self
    errors.add(:partner_id, "can't connect to yourself") if user_id == partner_id
  end
end
