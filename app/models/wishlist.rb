class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_items, dependent: :destroy

  # ActiveStorage attachments
  has_one_attached :cover_image

  # Analytics associations
  has_many :share_analytics, as: :shareable, dependent: :destroy

  # Activity Feed associations (as target)
  has_many :activity_feeds, as: :target, dependent: :destroy

  # User Interactions associations (as target)
  has_many :user_interactions, as: :target, dependent: :destroy

  # Comments associations (as commentable)
  has_many :activity_comments, as: :commentable, dependent: :destroy

  enum :visibility, { private_list: 0, partner_only: 1, publicly_visible: 2 }
  
  EVENT_TYPES = {
    'none' => 'General Wishlist',
    'birthday' => 'Birthday',
    'wedding' => 'Wedding',
    'baby_shower' => 'Baby Shower',
    'christmas' => 'Christmas',
    'anniversary' => 'Anniversary',
    'graduation' => 'Graduation',
    'housewarming' => 'Housewarming',
    'valentines' => "Valentine's Day",
    'mothers_day' => "Mother's Day",
    'fathers_day' => "Father's Day",
    'other' => 'Other Special Event'
  }.freeze

  validates :name, presence: true
  validates :visibility, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES.keys }, allow_nil: true

  scope :default_lists, -> { where(is_default: true) }
  scope :custom_lists, -> { where(is_default: false) }
  scope :public_lists, -> { where(visibility: :publicly_visible) }
  scope :visible_to_friends, -> { where(visibility: [:publicly_visible, :partner_only]) }
  scope :upcoming_events, -> { where('event_date >= ?', Date.current).where.not(event_type: ['none', nil]).order(event_date: :asc) }
  scope :past_events, -> { where('event_date < ?', Date.current).where.not(event_type: ['none', nil]).order(event_date: :desc) }
  scope :general_wishlists, -> { where(event_type: ['none', nil]).or(where(event_date: nil)) }
  scope :event_wishlists, -> { where.not(event_type: ['none', nil]).where.not(event_date: nil) }
  
  def days_until_event
    return nil unless event_date && !general_wishlist?
    (event_date - Date.current).to_i
  end
  
  def event_passed?
    return false unless event_date && !general_wishlist?
    event_date < Date.current
  end
  
  def general_wishlist?
    event_type.nil? || event_type == 'none' || event_date.nil?
  end
  
  def event_type_display
    return I18n.t('wishlists.event_types.none') if event_type.nil? || event_type == 'none'
    I18n.t("wishlists.event_types.#{event_type}", default: EVENT_TYPES[event_type] || 'General Wishlist')
  end

  def cover_image_url(variant = :card)
    return nil unless cover_image.attached?

    begin
      case variant
      when :thumb
        cover_image.variant(resize_to_fill: [300, 200])
      when :card
        cover_image.variant(resize_to_fill: [400, 250])
      when :hero
        cover_image.variant(resize_to_fill: [800, 400])
      else
        cover_image
      end
    rescue => e
      Rails.logger.error "Error generating cover image URL for wishlist #{id}: #{e.message}"
      # Return the original image as fallback
      cover_image
    end
  end
end
