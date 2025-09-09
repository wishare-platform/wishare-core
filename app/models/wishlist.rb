class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_items, dependent: :destroy

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
    EVENT_TYPES[event_type] || 'General Wishlist'
  end
end
