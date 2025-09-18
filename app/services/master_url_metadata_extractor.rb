require 'digest'

class MasterUrlMetadataExtractor
  # Extraction methods in order of preference
  EXTRACTION_METHODS = %i[
    database_cached
    memory_cached
    api_based
    enhanced_html
    standard_html
  ].freeze

  # Memory cache duration (1 hour for quick access)
  MEMORY_CACHE_TTL = 1.hour

  def initialize(url, options = {})
    @url = normalize_url(url)
    @options = options
    @metadata = {}
  end

  def extract
    return {} if @url.blank?

    # Try each extraction method in order
    EXTRACTION_METHODS.each do |method|
      next if @options[:skip_methods]&.include?(method)

      result = send("extract_via_#{method}")
      if result.present? && has_minimum_data?(result)
        @metadata = enhance_metadata(result)

        # Store in both caches unless it came from cache
        unless [:database_cached, :memory_cached].include?(method)
          store_in_caches(@metadata)
        end

        return @metadata
      end
    end

    # Return whatever we got, even if incomplete
    @metadata
  end

  private

  def extract_via_database_cached
    return nil if @options[:skip_database_cache]

    cached = UrlMetadataCache.fetch(@url)
    if cached
      Rails.logger.info "Using database cached metadata for #{@url} (hits: #{cached[:hit_count]})"

      # Also store in memory cache for faster subsequent access
      Rails.cache.write(memory_cache_key, cached, expires_in: MEMORY_CACHE_TTL)

      cached
    else
      nil
    end
  end

  def extract_via_memory_cached
    return nil unless Rails.cache.exist?(memory_cache_key)

    cached = Rails.cache.read(memory_cache_key)
    Rails.logger.info "Using memory cached metadata for #{@url}"
    cached
  end

  def extract_via_api_based
    return nil if @options[:skip_api]

    Rails.logger.info "Trying API extraction for #{@url}"
    ApiMetadataExtractor.new(@url).extract
  rescue => e
    Rails.logger.warn "API extraction failed: #{e.message}"
    nil
  end

  def extract_via_enhanced_html
    Rails.logger.info "Trying enhanced HTML extraction for #{@url}"
    EnhancedUrlMetadataExtractor.new(@url).extract
  rescue => e
    Rails.logger.warn "Enhanced extraction failed: #{e.message}"
    nil
  end

  def extract_via_standard_html
    Rails.logger.info "Trying standard HTML extraction for #{@url}"
    UrlMetadataExtractor.new(@url).extract
  rescue => e
    Rails.logger.warn "Standard extraction failed: #{e.message}"
    nil
  end

  def has_minimum_data?(metadata)
    # For product pages, we need more complete data
    if looks_like_product_page?
      # For product pages, require title AND price for truly complete data
      # Having just title and image isn't sufficient for shopping
      metadata[:title].present? && metadata[:price].present? && metadata[:price] > 0
    else
      # For other pages, title or description is sufficient
      metadata[:title].present? || metadata[:description].present?
    end
  end

  def looks_like_product_page?
    # Check if URL looks like a product page
    product_indicators = [
      '/product', '/item', '/p/', '/tenis', '/shoes', '/clothing',
      'produto', 'artigo', 'loja', 'shop', 'store'
    ]

    product_indicators.any? { |indicator| @url.downcase.include?(indicator) }
  end

  def enhance_metadata(metadata)
    # Clean and enhance the metadata
    enhanced = metadata.dup

    # Clean title
    if enhanced[:title].present?
      enhanced[:title] = clean_title(enhanced[:title])
    end

    # Clean description
    if enhanced[:description].present?
      enhanced[:description] = truncate_description(enhanced[:description])
    end

    # Validate price
    if enhanced[:price].present?
      enhanced[:price] = validate_price(enhanced[:price])
    end

    # Ensure currency
    enhanced[:currency] ||= detect_currency_from_url || 'USD'

    # Add extraction metadata
    enhanced[:extracted_at] = Time.current
    enhanced[:extraction_method] = @metadata[:extraction_method] || 'unknown'

    enhanced
  end

  def clean_title(title)
    title.strip
         .gsub(/\s+/, ' ')
         .gsub(/[^\w\s\-–—\(\)\[\]\.,:;&!?'"]/u, '')
         .truncate(200)
  end

  def truncate_description(description)
    description.strip
               .gsub(/\s+/, ' ')
               .truncate(500)
  end

  def validate_price(price)
    # Ensure price is reasonable
    price_float = price.to_f
    return nil if price_float <= 0 || price_float > 1_000_000
    price_float
  end

  def detect_currency_from_url
    # Quick currency detection based on domain
    domain = URI.parse(@url).host.downcase rescue nil
    return nil unless domain

    case domain
    when /\.br$/, /brasil/, /brazil/
      'BRL'
    when /\.uk$/, /\.co\.uk$/
      'GBP'
    when /\.de$/, /\.fr$/, /\.it$/, /\.es$/, /\.eu$/
      'EUR'
    when /\.ca$/
      'CAD'
    when /\.au$/, /\.com\.au$/
      'AUD'
    when /\.jp$/, /\.co\.jp$/
      'JPY'
    when /\.in$/, /\.co\.in$/
      'INR'
    when /\.cn$/
      'CNY'
    when /\.kr$/
      'KRW'
    when /\.mx$/
      'MXN'
    else
      nil
    end
  end

  def normalize_url(url)
    return nil if url.blank?

    # Add protocol if missing
    url = "https://#{url}" unless url.match?(/^https?:\/\//)

    # Remove tracking parameters
    uri = URI.parse(url)
    if uri.query
      params = CGI.parse(uri.query)
      # Remove common tracking parameters
      tracking_params = %w[utm_source utm_medium utm_campaign utm_term utm_content
                          fbclid gclid ref affiliate_id source]
      params.reject! { |k, _| tracking_params.include?(k.downcase) }
      uri.query = params.any? ? URI.encode_www_form(params) : nil
    end

    uri.to_s
  rescue URI::InvalidURIError
    url
  end

  def memory_cache_key
    "url_metadata:memory:#{Digest::SHA256.hexdigest(@url)}"
  end

  def store_in_caches(metadata)
    return if metadata.blank?

    # Store in database cache for global sharing
    begin
      UrlMetadataCache.store(@url, metadata)
      Rails.logger.info "Stored metadata in database cache for #{@url}"
    rescue => e
      Rails.logger.error "Failed to store in database cache: #{e.message}"
    end

    # Store in memory cache for fast access
    Rails.cache.write(memory_cache_key, metadata, expires_in: MEMORY_CACHE_TTL)
    Rails.logger.info "Stored metadata in memory cache for #{@url}"
  end
end

# Service for background metadata extraction
class MetadataExtractionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  def perform(url, wishlist_item_id = nil)
    metadata = MasterUrlMetadataExtractor.new(url).extract

    if wishlist_item_id && metadata.present?
      wishlist_item = WishlistItem.find_by(id: wishlist_item_id)
      if wishlist_item
        wishlist_item.update!(
          name: wishlist_item.name.presence || metadata[:title],
          description: wishlist_item.description.presence || metadata[:description],
          price: wishlist_item.price.presence || metadata[:price],
          currency: wishlist_item.currency.presence || metadata[:currency],
          image_url: wishlist_item.image_url.presence || metadata[:image]
        )
      end
    end

    metadata
  end
end