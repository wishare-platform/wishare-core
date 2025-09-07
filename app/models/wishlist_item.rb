class WishlistItem < ApplicationRecord
  belongs_to :wishlist
  belongs_to :purchased_by, class_name: 'User', optional: true

  enum :priority, { low: 0, medium: 1, high: 2 }
  enum :status, { available: 0, purchased: 1, reserved: 2 }

  validates :name, presence: true
  validates :priority, presence: true
  validates :status, presence: true
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validates :url, uniqueness: { scope: :wishlist_id, message: "This item has already been added to your wishlist" }, if: :url?
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  before_validation :extract_metadata_from_url, if: :url_changed?

  private

  def extract_metadata_from_url
    return if url.blank?
    
    metadata = UrlMetadataExtractor.new(url).extract
    self.name = metadata[:title] if name.blank? && metadata[:title].present?
    self.description = metadata[:description] if description.blank? && metadata[:description].present?
    self.image_url = metadata[:image] if image_url.blank? && metadata[:image].present?
    self.price = metadata[:price] if price.blank? && metadata[:price].present?
  end
end
