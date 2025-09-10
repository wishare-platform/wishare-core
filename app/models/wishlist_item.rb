class WishlistItem < ApplicationRecord
  belongs_to :wishlist
  belongs_to :purchased_by, class_name: 'User', optional: true

  enum :priority, { low: 0, medium: 1, high: 2 }
  enum :status, { available: 0, purchased: 1, reserved: 2 }

  validates :name, presence: true
  validates :priority, presence: true
  validates :status, presence: true
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validate :unique_normalized_url, if: :url?
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  before_validation :extract_metadata_from_url, if: :url_changed?

  # Class method to normalize URLs for comparison
  def self.normalize_url(url)
    return nil if url.blank?
    
    begin
      uri = URI.parse(url.strip)
      # Remove query parameters, fragments, and normalize
      normalized = "#{uri.scheme}://#{uri.host.downcase}#{uri.path}"
      # Remove trailing slash unless it's the root path
      normalized = normalized.chomp('/') unless normalized.end_with?(':///')
      normalized
    rescue URI::InvalidURIError
      url.strip
    end
  end

  # Instance method to get normalized URL for this item
  def normalized_url
    self.class.normalize_url(url)
  end

  private

  def extract_metadata_from_url
    return if url.blank?
    
    metadata = UrlMetadataExtractor.new(url).extract
    self.name = metadata[:title] if name.blank? && metadata[:title].present?
    self.description = metadata[:description] if description.blank? && metadata[:description].present?
    self.image_url = metadata[:image] if image_url.blank? && metadata[:image].present?
    self.price = metadata[:price] if price.blank? && metadata[:price].present?
  end

  def unique_normalized_url
    return if url.blank?
    
    normalized = normalized_url
    return if normalized.blank?
    
    # Check if any other item in the same wishlist has the same normalized URL
    existing = wishlist.wishlist_items
                      .where.not(id: id) # Exclude current record for updates
                      .where.not(url: [nil, '']) # Only check items with URLs
    
    existing.find_each do |item|
      if self.class.normalize_url(item.url) == normalized
        errors.add(:url, "This item has already been added to your wishlist")
        break
      end
    end
  end
end
