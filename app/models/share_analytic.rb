class ShareAnalytic < ApplicationRecord
  belongs_to :user
  belongs_to :shareable, polymorphic: true

  validates :platform, presence: true, inclusion: { in: %w[whatsapp twitter facebook linkedin telegram copy_link native_share] }
  validates :shared_at, presence: true
  validates :clicks, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(shared_at: :desc) }
  scope :popular, -> { order(clicks: :desc) }

  def increment_clicks!
    increment!(:clicks)
  end

  def self.track_share(user, shareable, platform)
    create!(
      user: user,
      shareable: shareable,
      platform: platform.to_s,
      shared_at: Time.current
    )
  end

  def self.popular_content(limit = 10)
    joins(:shareable)
      .group(:shareable_type, :shareable_id)
      .order('SUM(clicks) DESC')
      .limit(limit)
      .includes(:shareable)
  end

  def self.platform_stats
    group(:platform).sum(:clicks)
  end
end
