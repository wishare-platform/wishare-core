require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'
require 'ipaddr'
require 'resolv'

class UrlMetadataExtractor
  TIMEOUT = 10
  MAX_REDIRECTS = 5

  CURRENCY_PATTERNS = {
    # Amazon domains and their currencies
    'amazon.com' => 'USD',
    'amazon.com.br' => 'BRL',
    'amazon.co.uk' => 'GBP',
    'amazon.de' => 'EUR',
    'amazon.fr' => 'EUR',
    'amazon.it' => 'EUR',
    'amazon.es' => 'EUR',
    'amazon.ca' => 'CAD',
    'amazon.com.au' => 'AUD',
    'amazon.co.jp' => 'JPY',
    'amazon.in' => 'INR',
    
    # Major retailers
    'shopify.com' => 'USD',
    'etsy.com' => 'USD',
    'ebay.com' => 'USD',
    'ebay.co.uk' => 'GBP',
    'ebay.de' => 'EUR',
    'mercadolivre.com.br' => 'BRL',
    'magazineluiza.com.br' => 'BRL',
    'americanas.com.br' => 'BRL',
    'casasbahia.com.br' => 'BRL',
    'zalando.de' => 'EUR',
    'zalando.co.uk' => 'GBP',
    'asos.com' => 'GBP',
    'hm.com' => 'USD',
    'zara.com' => 'USD',
    'target.com' => 'USD',
    'walmart.com' => 'USD',
    'bestbuy.com' => 'USD',
    'apple.com' => 'USD',
    'nike.com.br' => 'BRL',
    'nike.com' => 'USD',
    'adidas.com.br' => 'BRL',
    'adidas.com' => 'USD'
  }.freeze

  CURRENCY_REGEX_PATTERNS = [
    # Price patterns with currency symbols
    /\$\s*([0-9,]+\.?[0-9]*)/i,           # $99.99 or $1,299
    /R\$\s*([0-9.,]+)/i,                  # R$ 99,99
    /€\s*([0-9,]+\.?[0-9]*)/i,            # €99.99
    /£\s*([0-9,]+\.?[0-9]*)/i,            # £99.99
    /¥\s*([0-9,]+)/i,                     # ¥9999
    /₹\s*([0-9,]+\.?[0-9]*)/i,            # ₹999.99
    # Text-based currency patterns
    /([0-9,]+\.?[0-9]*)\s*(USD|BRL|EUR|GBP|JPY|INR|CAD|AUD)/i,
    # Meta property patterns
    /content=["']([A-Z]{3}):([0-9.]+)["']/i
  ].freeze

  def initialize(url)
    @url = url
    @metadata = {}
  end

  def extract
    return {} if @url.blank?

    begin
      uri = URI.parse(@url)
      return {} unless %w[http https].include?(uri.scheme)

      # SSRF Protection: Validate the URL is not pointing to internal resources
      return {} unless safe_url?(uri)

      response = fetch_with_redirects(uri)
      return {} unless response.is_a?(Net::HTTPSuccess)

      content_type = response.content_type
      html = response.body

      if content_type&.include?('text/html')
        extract_from_html(html)
      end

      @metadata
    rescue => e
      Rails.logger.warn "URL metadata extraction failed for #{@url}: #{e.message}"
      {}
    end
  end

  private

  def safe_url?(uri)
    # Block private IP addresses and localhost
    return false if uri.host.nil?

    # Resolve hostname to IP address
    begin
      require 'resolv'
      ip = Resolv.getaddress(uri.host)
      addr = IPAddr.new(ip)

      # Block private and reserved IP ranges
      return false if addr.private?
      return false if addr.loopback?
      return false if addr.link_local?
      return false if addr.multicast?
      return false if ip == '0.0.0.0' || ip.start_with?('0.')
      return false if ip == '::' || ip == '::1'

      # Block common internal hostnames
      blocked_hosts = %w[localhost 127.0.0.1 0.0.0.0 ::1 metadata.google.internal]
      return false if blocked_hosts.include?(uri.host.downcase)

      # Block internal cloud metadata endpoints
      return false if uri.host =~ /^169\.254\./
      return false if uri.host =~ /metadata/i

      true
    rescue => e
      Rails.logger.warn "Failed to validate URL safety for #{uri}: #{e.message}"
      false
    end
  end

  def fetch_with_redirects(uri, redirects = 0)
    return nil if redirects > MAX_REDIRECTS

    # Validate each redirect is also safe
    return nil unless safe_url?(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = TIMEOUT
    http.open_timeout = TIMEOUT

    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Mozilla/5.0 (compatible; CupidGifts/1.0)'

    response = http.request(request)

    case response
    when Net::HTTPRedirection
      new_uri = URI.parse(response['location'])
      new_uri = uri + response['location'] unless new_uri.absolute?
      fetch_with_redirects(new_uri, redirects + 1)
    else
      response
    end
  end

  def extract_from_html(html)
    doc = Nokogiri::HTML(html)

    extract_title(doc)
    extract_description(doc)
    extract_image(doc)
    extract_price(doc)
    extract_currency(doc, html)
    extract_open_graph_data(doc)
    extract_json_ld_data(doc)
  end

  def extract_title(doc)
    title = doc.css('meta[property="og:title"]').first&.[]('content') ||
            doc.css('meta[name="twitter:title"]').first&.[]('content') ||
            doc.css('title').first&.text

    @metadata[:title] = title&.strip if title.present?
  end

  def extract_description(doc)
    description = doc.css('meta[property="og:description"]').first&.[]('content') ||
                  doc.css('meta[name="twitter:description"]').first&.[]('content') ||
                  doc.css('meta[name="description"]').first&.[]('content')

    @metadata[:description] = description&.strip if description.present?
  end

  def extract_image(doc)
    image = doc.css('meta[property="og:image"]').first&.[]('content') ||
            doc.css('meta[name="twitter:image"]').first&.[]('content')

    if image.present?
      # Convert relative URLs to absolute
      image_uri = URI.parse(image)
      unless image_uri.absolute?
        base_uri = URI.parse(@url)
        image = (base_uri + image).to_s
      end
      @metadata[:image] = image
    end
  end

  def extract_price(doc)
    # Look for common price patterns
    price_selectors = [
      'meta[property="product:price:amount"]',
      'meta[property="og:price:amount"]',
      '.price',
      '[data-price]',
      '.cost',
      '.amount'
    ]

    price_selectors.each do |selector|
      element = doc.css(selector).first
      next unless element

      price_text = element['content'] || element.text
      price = extract_price_from_text(price_text)
      if price
        @metadata[:price] = price
        break
      end
    end
  end

  def extract_currency(doc, html_content)
    # Method 1: Domain-based detection
    domain_currency = detect_currency_from_domain
    if domain_currency
      @metadata[:currency] = domain_currency
      return
    end

    # Method 2: Meta tags
    meta_currency = extract_currency_from_meta_tags(doc)
    if meta_currency
      @metadata[:currency] = meta_currency
      return
    end

    # Method 3: Content analysis
    content_currency = detect_currency_from_content(html_content)
    if content_currency
      @metadata[:currency] = content_currency
      return
    end

    # Method 4: URL analysis (for country-specific subdomains)
    url_currency = detect_currency_from_url_structure
    if url_currency
      @metadata[:currency] = url_currency
      return
    end

    # Default fallback
    @metadata[:currency] = 'USD'
  end

  def extract_open_graph_data(doc)
    # Extract additional Open Graph data
    doc.css('meta[property^="og:"]').each do |meta|
      property = meta['property']
      content = meta['content']
      
      case property
      when 'og:type'
        @metadata[:type] = content
      when 'og:url'
        @metadata[:canonical_url] = content
      end
    end
  end

  def extract_json_ld_data(doc)
    # Extract structured data (JSON-LD)
    doc.css('script[type="application/ld+json"]').each do |script|
      begin
        data = JSON.parse(script.content)
        extract_from_json_ld(data)
      rescue JSON::ParserError
        next
      end
    end
  end

  def extract_from_json_ld(data)
    return unless data.is_a?(Hash)

    # Handle Product schema
    if data['@type'] == 'Product' || data['@type']&.include?('Product')
      @metadata[:title] ||= data['name']
      @metadata[:description] ||= data['description']
      
      if data['offers']
        offers = data['offers'].is_a?(Array) ? data['offers'].first : data['offers']
        if offers['price']
          @metadata[:price] ||= offers['price'].to_f
        end
        if offers['priceCurrency'] && WishlistItem::CURRENCIES.key?(offers['priceCurrency'].upcase)
          @metadata[:currency] ||= offers['priceCurrency'].upcase
        end
      end
      
      if data['image']
        image = data['image'].is_a?(Array) ? data['image'].first : data['image']
        image_url = image.is_a?(Hash) ? image['url'] : image
        @metadata[:image] ||= image_url
      end
    end

    # Handle array of items
    if data.is_a?(Array)
      data.each { |item| extract_from_json_ld(item) }
    end
  end

  def extract_price_from_text(text)
    return nil if text.blank?

    # Remove common currency symbols and extract number
    cleaned = text.gsub(/[^\d.,]/, '')
    return nil if cleaned.blank?

    # Handle different decimal separators
    if cleaned.count('.') == 1 && cleaned.count(',') == 0
      # Format: 123.45
      cleaned.to_f
    elsif cleaned.count(',') == 1 && cleaned.count('.') == 0
      # Format: 123,45 (European style)
      cleaned.gsub(',', '.').to_f
    elsif cleaned.count('.') > 1 && cleaned.count(',') == 1
      # Format: 1.234,56 (European style with thousands separator)
      cleaned.gsub('.', '').gsub(',', '.').to_f
    elsif cleaned.count(',') > 1 && cleaned.count('.') == 1
      # Format: 1,234.56 (US style with thousands separator)
      cleaned.gsub(',', '').to_f
    else
      # Fallback: just extract the first number
      text.scan(/[\d.,]+/).first&.to_f
    end
  end

  def detect_currency_from_domain
    return nil if @url.blank?
    
    uri = URI.parse(@url)
    domain = uri.host.downcase
    
    # Sort patterns by length (longest first) to match more specific domains first
    sorted_patterns = CURRENCY_PATTERNS.sort_by { |pattern, _| -pattern.length }
    
    sorted_patterns.each do |pattern, currency|
      # Use exact match or ends_with for more precise matching
      if domain == pattern || domain.end_with?(".#{pattern}") || domain.end_with?(pattern)
        return currency
      end
    end
    
    nil
  rescue
    nil
  end

  def extract_currency_from_meta_tags(doc)
    # OpenGraph currency
    currency = doc.at_css('meta[property="product:price:currency"]')&.[]('content')
    return currency.upcase if currency && WishlistItem::CURRENCIES.key?(currency.upcase)

    # Schema.org microdata
    currency = doc.at_css('[itemprop="priceCurrency"]')&.[]('content')
    return currency.upcase if currency && WishlistItem::CURRENCIES.key?(currency.upcase)

    # JSON-LD structured data
    scripts = doc.css('script[type="application/ld+json"]')
    scripts.each do |script|
      begin
        data = JSON.parse(script.content)
        currency = extract_currency_from_json_ld(data)
        return currency if currency
      rescue JSON::ParserError
        next
      end
    end

    nil
  end

  def extract_currency_from_json_ld(data)
    return nil unless data.is_a?(Hash)

    # Handle arrays
    if data.is_a?(Array)
      data.each do |item|
        currency = extract_currency_from_json_ld(item)
        return currency if currency
      end
      return nil
    end

    # Look for price currency in product schema
    if data['@type'] == 'Product' && data['offers']
      offers = data['offers'].is_a?(Array) ? data['offers'] : [data['offers']]
      offers.each do |offer|
        currency = offer['priceCurrency']
        return currency.upcase if currency && WishlistItem::CURRENCIES.key?(currency.upcase)
      end
    end

    # Recursively search nested objects
    data.each_value do |value|
      if value.is_a?(Hash) || value.is_a?(Array)
        currency = extract_currency_from_json_ld(value)
        return currency if currency
      end
    end

    nil
  end

  def detect_currency_from_content(html_content)
    # Look for currency symbols and patterns in the content
    CURRENCY_REGEX_PATTERNS.each do |pattern|
      match = html_content.match(pattern)
      next unless match

      case pattern.source
      when /\\\$/
        return 'USD'
      when /R\\\$/
        return 'BRL'
      when /€/
        return 'EUR'
      when /£/
        return 'GBP'
      when /¥/
        # Could be JPY or CNY, default to JPY
        return 'JPY'
      when /₹/
        return 'INR'
      when /([A-Z]{3})/
        currency = match[2] || match[1]
        return currency.upcase if WishlistItem::CURRENCIES.key?(currency.upcase)
      end
    end

    nil
  end

  def detect_currency_from_url_structure
    return nil if @url.blank?
    
    uri = URI.parse(@url)
    
    # Country code in subdomain (e.g., br.site.com, uk.site.com)
    subdomain = uri.host.split('.').first
    
    country_to_currency = {
      'br' => 'BRL',
      'uk' => 'GBP',
      'de' => 'EUR',
      'fr' => 'EUR',
      'it' => 'EUR',
      'es' => 'EUR',
      'ca' => 'CAD',
      'au' => 'AUD',
      'jp' => 'JPY',
      'in' => 'INR',
      'mx' => 'MXN',
      'kr' => 'KRW',
      'cn' => 'CNY'
    }

    country_to_currency[subdomain]
  rescue
    nil
  end
end