class WishlistItem < ApplicationRecord
  belongs_to :wishlist
  belongs_to :purchased_by, class_name: 'User', optional: true

  # Analytics associations
  has_many :share_analytics, as: :shareable, dependent: :destroy

  # Activity Feed associations (as target)
  has_many :activity_feeds, as: :target, dependent: :destroy

  # User Interactions associations (as target)
  has_many :user_interactions, as: :target, dependent: :destroy

  # Comments associations (as commentable)
  has_many :activity_comments, as: :commentable, dependent: :destroy

  enum :priority, { low: 0, medium: 1, high: 2 }
  enum :status, { available: 0, purchased: 1, reserved: 2 }

  CURRENCIES = {
    'BRL' => { symbol: 'R$', name: 'Brazilian Real' },
    'USD' => { symbol: '$', name: 'US Dollar' },
    'EUR' => { symbol: '€', name: 'Euro' },
    'GBP' => { symbol: '£', name: 'British Pound' },
    'JPY' => { symbol: '¥', name: 'Japanese Yen' },
    'CAD' => { symbol: 'C$', name: 'Canadian Dollar' },
    'AUD' => { symbol: 'A$', name: 'Australian Dollar' },
    'CHF' => { symbol: 'CHF', name: 'Swiss Franc' },
    'CNY' => { symbol: '¥', name: 'Chinese Yuan' },
    'INR' => { symbol: '₹', name: 'Indian Rupee' },
    'KRW' => { symbol: '₩', name: 'South Korean Won' },
    'MXN' => { symbol: 'MX$', name: 'Mexican Peso' },
    'SGD' => { symbol: 'S$', name: 'Singapore Dollar' },
    'NOK' => { symbol: 'kr', name: 'Norwegian Krone' },
    'SEK' => { symbol: 'kr', name: 'Swedish Krona' },
    'DKK' => { symbol: 'kr', name: 'Danish Krone' },
    'PLN' => { symbol: 'zł', name: 'Polish Zloty' },
    'CZK' => { symbol: 'Kč', name: 'Czech Koruna' },
    'HUF' => { symbol: 'Ft', name: 'Hungarian Forint' },
    'RUB' => { symbol: '₽', name: 'Russian Ruble' }
  }.freeze

  PRIORITY_CURRENCIES = %w[BRL USD EUR GBP JPY CAD AUD].freeze

  validates :name, presence: true
  validates :priority, presence: true
  validates :status, presence: true
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true
  validate :unique_normalized_url, if: :url?
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :currency, inclusion: { in: CURRENCIES.keys }

  before_validation :extract_metadata_from_url, if: :url_changed?

  # Class method to normalize URLs for comparison
  def self.normalize_url(url)
    return nil if url.blank?
    
    begin
      uri = URI.parse(url.strip)
      # Only normalize scheme and host case, keep the full path
      # Remove query parameters and fragments for comparison
      normalized = "#{uri.scheme.downcase}://#{uri.host.downcase}#{uri.path}"
      # Remove trailing slash unless it's the root path
      normalized = normalized.chomp('/') unless uri.path == '/'
      normalized
    rescue URI::InvalidURIError
      url.strip
    end
  end

  # Instance method to get normalized URL for this item
  def normalized_url
    self.class.normalize_url(url)
  end

  # Safe URL for rendering in views (prevents XSS)
  def safe_url
    return nil if url.blank?
    
    # Only allow http and https protocols
    uri = URI.parse(url)
    return url if %w[http https].include?(uri.scheme&.downcase)
    nil
  rescue URI::InvalidURIError
    nil
  end

  def currency_symbol
    CURRENCIES[currency || 'USD'][:symbol]
  end

  def currency_name
    CURRENCIES[currency || 'USD'][:name]
  end

  def formatted_price
    return I18n.t('wishlists.show.price_not_set', default: 'Price not set') unless price.present?
    
    # Format price based on currency conventions
    case currency
    when 'BRL'
      # Brazilian format: R$ 1.234,56
      "R$ #{number_with_delimiter(price.to_f.round(2), delimiter: '.', separator: ',')}"
    when 'EUR'
      # Euro format: €1,234.56 or 1.234,56 € (using US format for consistency)
      "€#{number_with_delimiter(price.to_f.round(2), delimiter: ',', separator: '.')}"
    when 'GBP'
      # British format: £1,234.56
      "£#{number_with_delimiter(price.to_f.round(2), delimiter: ',', separator: '.')}"
    when 'JPY', 'KRW'
      # Japanese/Korean format: ¥1,234 (no decimals)
      "#{currency_symbol}#{number_with_delimiter(price.to_i, delimiter: ',')}"
    else
      # Default format (USD, CAD, AUD, etc.): $1,234.56
      "#{currency_symbol}#{number_with_delimiter(price.to_f.round(2), delimiter: ',', separator: '.')}"
    end
  end
  
  private
  
  def number_with_delimiter(number, delimiter: ',', separator: '.')
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join(separator)
  end

  def extract_metadata_from_url
    return if url.blank?
    
    metadata = UrlMetadataExtractor.new(url).extract
    self.name = metadata[:title] if name.blank? && metadata[:title].present?
    self.description = metadata[:description] if description.blank? && metadata[:description].present?
    self.image_url = metadata[:image] if image_url.blank? && metadata[:image].present?
    self.price = metadata[:price] if price.blank? && metadata[:price].present?
    self.currency = metadata[:currency] if currency.blank? && metadata[:currency].present? && CURRENCIES.key?(metadata[:currency])
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
