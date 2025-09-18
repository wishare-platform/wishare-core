require 'net/http'
require 'uri'
require 'json'

class ApiMetadataExtractor
  # External API services for enhanced extraction
  # Note: These would require API keys in production
  API_SERVICES = {
    # Free tier services
    linkpreview: {
      url: 'https://api.linkpreview.net',
      requires_key: true,
      key_env: 'LINKPREVIEW_API_KEY'
    },
    microlink: {
      url: 'https://api.microlink.io',
      requires_key: false
    },
    unfurl: {
      url: 'https://unfurl.io/api/v1/preview',
      requires_key: true,
      key_env: 'UNFURL_API_KEY'
    },
    scraperapi: {
      url: 'https://api.scraperapi.com',
      requires_key: true,
      key_env: 'SCRAPER_API_KEY'
    }
  }.freeze

  def initialize(url)
    @url = url
    @metadata = {}
  end

  def extract
    # Try each service in order of preference
    metadata = try_microlink || try_linkpreview || try_unfurl || {}

    # Normalize the response
    normalize_metadata(metadata)
  end

  private

  def try_microlink
    # Microlink is free and doesn't require API key
    begin
      uri = URI("https://api.microlink.io?url=#{CGI.escape(@url)}")
      response = fetch_with_timeout(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        if data['status'] == 'success' && data['data']
          return extract_from_microlink(data['data'])
        end
      end
    rescue => e
      Rails.logger.warn "Microlink API failed for #{@url}: #{e.message}"
    end
    nil
  end

  def try_linkpreview
    return nil unless ENV['LINKPREVIEW_API_KEY'].present?

    begin
      uri = URI('https://api.linkpreview.net')
      uri.query = URI.encode_www_form({
        key: ENV['LINKPREVIEW_API_KEY'],
        q: @url
      })

      response = fetch_with_timeout(uri)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        return extract_from_linkpreview(data)
      end
    rescue => e
      Rails.logger.warn "LinkPreview API failed for #{@url}: #{e.message}"
    end
    nil
  end

  def try_unfurl
    return nil unless ENV['UNFURL_API_KEY'].present?

    begin
      uri = URI('https://unfurl.io/api/v1/preview')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{ENV['UNFURL_API_KEY']}"
      request['Content-Type'] = 'application/json'
      request.body = { url: @url }.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        return extract_from_unfurl(data)
      end
    rescue => e
      Rails.logger.warn "Unfurl API failed for #{@url}: #{e.message}"
    end
    nil
  end

  def extract_from_microlink(data)
    {
      title: data['title'],
      description: data['description'],
      image: data['image']&.dig('url'),
      price: extract_price_from_microlink(data),
      currency: detect_currency_from_data(data),
      author: data['author'],
      publisher: data['publisher'],
      logo: data['logo']&.dig('url')
    }.compact
  end

  def extract_from_linkpreview(data)
    {
      title: data['title'],
      description: data['description'],
      image: data['image'],
      price: nil, # LinkPreview doesn't extract price
      currency: nil
    }.compact
  end

  def extract_from_unfurl(data)
    result = {
      title: data['title'],
      description: data['description'],
      image: data['image_url'] || data['thumbnail_url'],
      currency: data['currency']
    }

    # Add price if available
    result[:price] = extract_price_from_text(data['price']) if data['price']

    result.compact
  end

  def extract_price_from_microlink(data)
    # Microlink sometimes includes price in data
    if data['price']
      return extract_price_from_text(data['price'].to_s)
    end

    # Check in meta tags
    if data['meta'] && data['meta']['price']
      return extract_price_from_text(data['meta']['price'].to_s)
    end

    nil
  end

  def detect_currency_from_data(data)
    # Look for currency in various fields
    currency = data['currency'] ||
               data.dig('meta', 'currency') ||
               data.dig('meta', 'priceCurrency')

    currency&.upcase if currency && WishlistItem::CURRENCIES.key?(currency.upcase)
  end

  def fetch_with_timeout(uri, timeout = 10)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = timeout
    http.open_timeout = timeout

    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Wishare/1.0'

    http.request(request)
  end

  def normalize_metadata(metadata)
    return {} if metadata.blank?

    # Ensure all expected fields are present
    {
      title: clean_text(metadata[:title]),
      description: clean_text(metadata[:description]),
      image: normalize_url(metadata[:image]),
      price: metadata[:price],
      currency: metadata[:currency] || 'USD'
    }.compact
  end

  def clean_text(text)
    return nil if text.blank?
    text.strip.gsub(/\s+/, ' ')
  end

  def normalize_url(url)
    return nil if url.blank?

    # Handle protocol-relative URLs
    url = "https:#{url}" if url.start_with?('//')

    # Validate URL
    begin
      URI.parse(url)
      url
    rescue URI::InvalidURIError
      nil
    end
  end

  def extract_price_from_text(text)
    return nil if text.blank?

    # Remove currency symbols and extract number
    cleaned = text.gsub(/[^\d.,]/, '')
    return nil if cleaned.blank?

    # Handle different decimal separators
    if cleaned.count(',') == 1 && cleaned.count('.') == 0
      cleaned.gsub(',', '.').to_f
    else
      cleaned.gsub(',', '').to_f
    end
  end
end