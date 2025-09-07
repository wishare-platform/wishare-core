require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'

class UrlMetadataExtractor
  TIMEOUT = 10
  MAX_REDIRECTS = 5

  def initialize(url)
    @url = url
    @metadata = {}
  end

  def extract
    return {} if @url.blank?

    begin
      uri = URI.parse(@url)
      return {} unless %w[http https].include?(uri.scheme)

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

  def fetch_with_redirects(uri, redirects = 0)
    return nil if redirects > MAX_REDIRECTS

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
end