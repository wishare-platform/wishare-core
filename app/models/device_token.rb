class DeviceToken < ApplicationRecord
  belongs_to :user

  enum :platform, {
    ios: 0,
    android: 1,
    web: 2
  }

  validates :token, presence: true, uniqueness: { scope: :user_id }
  validates :platform, presence: true

  scope :active, -> { where(active: true) }
  scope :for_platform, ->(platform) { where(platform: platform) }

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def self.register_token(user:, token:, platform:)
    # Deactivate any existing tokens for this user/platform combination
    where(user: user, platform: platform).update_all(active: false)

    # Create or reactivate the token
    device_token = find_or_initialize_by(user: user, token: token, platform: platform)
    device_token.active = true
    device_token.last_used_at = Time.current
    device_token.save!

    device_token
  end

  def self.cleanup_expired_tokens
    # Remove tokens that haven't been used in 30 days
    where("last_used_at < ?", 30.days.ago).delete_all
  end
end
