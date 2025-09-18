class UrlMetadataCache < ApplicationRecord
  # Constants
  DEFAULT_CACHE_DURATION = 7.days
  PREMIUM_CACHE_DURATION = 30.days # For frequently accessed URLs
  MAX_CACHE_SIZE = 100_000 # Maximum number of cached URLs
  POPULARITY_THRESHOLD = 10 # Hits before extending cache duration

  # Validations
  validates :url, :normalized_url, :url_hash, presence: true
  validates :url_hash, uniqueness: true

  # Scopes
  scope :valid, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :popular, -> { where('hit_count >= ?', POPULARITY_THRESHOLD) }
  scope :by_platform, ->(platform) { where(platform: platform) }
  scope :recently_accessed, -> { order(last_accessed_at: :desc) }
  scope :most_popular, -> { order(hit_count: :desc) }

  # Callbacks
  before_validation :set_defaults
  after_find :track_access

  # Class methods
  class << self
    def fetch(url)
      normalized = normalize_url(url)
      hash = generate_hash(normalized)

      cache = valid.find_by(url_hash: hash)

      if cache
        cache.increment!(:hit_count)
        cache.touch(:last_accessed_at)

        # Extend cache duration for popular items
        if cache.popular? && cache.expires_at < 14.days.from_now
          cache.update!(expires_at: PREMIUM_CACHE_DURATION.from_now)
        end

        cache.to_metadata
      else
        nil
      end
    end

    def store(url, metadata, options = {})
      normalized = normalize_url(url)
      hash = generate_hash(normalized)

      # Determine cache duration based on platform and popularity
      duration = options[:duration] || DEFAULT_CACHE_DURATION
      platform = metadata[:platform] || detect_platform(url)

      # Premium platforms get longer cache
      if %w[amazon mercadolivre nike adidas sephora].include?(platform.to_s)
        duration = PREMIUM_CACHE_DURATION
      end

      cache = find_or_initialize_by(url_hash: hash)
      cache.assign_attributes(
        url: url,
        normalized_url: normalized,
        title: metadata[:title],
        description: metadata[:description],
        image_url: metadata[:image],
        price: metadata[:price],
        currency: metadata[:currency],
        platform: platform,
        extraction_method: metadata[:extraction_method],
        metadata: metadata,
        extracted_at: Time.current,
        expires_at: duration.from_now
      )

      cache.save!
      cache
    end

    def normalize_url(url)
      return nil if url.blank?

      # Add protocol if missing
      url = "https://#{url}" unless url.match?(/^https?:\/\//)

      begin
        uri = URI.parse(url)

        # Remove tracking parameters
        if uri.query
          params = CGI.parse(uri.query)
          # Keep product-specific params, remove tracking
          tracking_params = %w[utm_source utm_medium utm_campaign utm_term utm_content
                              fbclid gclid ref affiliate_id source tag]
          params.reject! { |k, _| tracking_params.include?(k.downcase) }
          uri.query = params.any? ? URI.encode_www_form(params) : nil
        end

        # Remove fragment
        uri.fragment = nil

        # Lowercase host
        uri.host = uri.host.downcase if uri.host

        uri.to_s
      rescue URI::InvalidURIError
        url
      end
    end

    def generate_hash(normalized_url)
      Digest::SHA256.hexdigest(normalized_url)
    end

    def detect_platform(url)
      return nil if url.blank?

      host = URI.parse(url).host.downcase rescue nil
      return nil unless host

      case host
      when /amazon/ then 'amazon'
      when /mercado/ then 'mercadolivre'
      when /nike/ then 'nike'
      when /adidas/ then 'adidas'
      when /sephora/ then 'sephora'
      when /magazineluiza|magalu/ then 'magazineluiza'
      when /shopify|myshopify/ then 'shopify'
      when /nuvemshop|tiendanube/ then 'nuvemshop'
      else 'unknown'
      end
    end

    def cleanup!
      # Remove expired entries
      expired_count = expired.delete_all

      # If we're over limit, remove least popular old entries
      if count > MAX_CACHE_SIZE
        excess = count - MAX_CACHE_SIZE
        least_popular = order(hit_count: :asc, last_accessed_at: :asc).limit(excess)
        removed_count = least_popular.delete_all

        Rails.logger.info "Cache cleanup: removed #{expired_count} expired and #{removed_count} excess entries"
      else
        Rails.logger.info "Cache cleanup: removed #{expired_count} expired entries"
      end
    end

    def statistics
      {
        total_cached: count,
        valid_cached: valid.count,
        expired: expired.count,
        popular_items: popular.count,
        platforms: group(:platform).count,
        total_hits: sum(:hit_count),
        avg_hits_per_url: average(:hit_count).to_f.round(2),
        cache_size_mb: (sum('length(metadata::text)').to_f / 1.megabyte).round(2),
        oldest_entry: minimum(:created_at),
        newest_entry: maximum(:created_at),
        most_popular_urls: most_popular.limit(10).pluck(:normalized_url, :hit_count)
      }
    end

    def warm_cache_for_popular_items
      # Re-fetch metadata for popular expired items
      popular.expired.find_each do |cache|
        MetadataExtractionJob.perform_later(cache.url, cache_only: true)
      end
    end
  end

  # Instance methods
  def to_metadata
    {
      title: title,
      description: description,
      image: image_url,
      price: price,
      currency: currency,
      platform: platform,
      cached: true,
      cached_at: extracted_at,
      cache_expires_at: expires_at
    }.merge(metadata || {})
  end

  def popular?
    hit_count >= POPULARITY_THRESHOLD
  end

  def expired?
    expires_at <= Time.current
  end

  def valid?
    expires_at > Time.current
  end

  def refresh!
    MetadataExtractionJob.perform_later(url, cache_id: id)
  end

  private

  def set_defaults
    self.extracted_at ||= Time.current
    self.expires_at ||= DEFAULT_CACHE_DURATION.from_now
    self.hit_count ||= 0
  end

  def track_access
    # This is called after find, but we update in fetch method
    # to avoid unnecessary callbacks
  end
end
