require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'
require 'ipaddr'
require 'resolv'

class EnhancedUrlMetadataExtractor < UrlMetadataExtractor
  # Comprehensive price selectors that work across most e-commerce sites
  PRICE_SELECTORS = [
    # Meta tags (highest priority)
    'meta[property="product:price:amount"]',
    'meta[property="og:price:amount"]',
    'meta[property="product:price"]',
    'meta[itemprop="price"]',

    # Common class-based selectors
    '.price-now',
    '.product-price',
    '.price-tag',
    '.current-price',
    '.sale-price',
    '.special-price',
    '.price-box .price',
    '.price-wrapper',
    '.product-price-value',
    '.price-regular',
    '.price__current',
    '.price--main',
    '.priceView-customer-price',

    # Data attributes (very reliable)
    '[data-price]',
    '[data-product-price]',
    '[data-sale-price]',
    '[data-price-amount]',
    '[data-testid*="price"]',
    '[data-test*="price"]',

    # ID-based selectors
    '#product-price',
    '#price',
    '#priceblock_dealprice',
    '#priceblock_ourprice',
    '#priceblock_saleprice',

    # Semantic HTML5
    '[itemprop="price"]',
    '[itemprop="offers"] [itemprop="price"]',

    # Common patterns by platform
    '.woocommerce-Price-amount',  # WooCommerce
    '.product-info__price',       # Shopify themes
    '.ProductMeta__Price',        # Shopify
    '.price__sale',               # Shopify
    '.money',                      # Shopify
    '.vtex-product-price',        # VTEX
    '.product-pricing',           # Magento
    '.price-box__price',          # Magento 2
    'span.price-item--sale',      # BigCommerce
    '.ec-price-item',             # Ecwid

    # Generic but common
    '.price',
    '.cost',
    '.amount',
    'span.price',
    'div.price',
    'p.price'
  ].freeze

  # Enhanced title selectors
  TITLE_SELECTORS = [
    # Meta tags (highest priority)
    'meta[property="og:title"]',
    'meta[name="twitter:title"]',
    'meta[itemprop="name"]',

    # Product-specific
    'h1.product-title',
    'h1.product-name',
    'h1[itemprop="name"]',
    '.product-info__title',
    '.product-name',
    '.ProductMeta__Title',
    '#product-title',
    '[data-testid="product-title"]',
    '[data-test="product-name"]',

    # Generic
    'h1',
    'title'
  ].freeze

  # Enhanced image selectors
  IMAGE_SELECTORS = [
    # Meta tags
    'meta[property="og:image"]',
    'meta[name="twitter:image"]',
    'meta[itemprop="image"]',

    # Product images
    '.product-image img',
    '.product-photo img',
    '.gallery-image img',
    '.product-image-main img',
    '[data-testid="product-image"] img',
    '.zoomable img',
    '.product__main-photos img',
    '.ProductPhotoContainer img',

    # Common patterns
    'img[itemprop="image"]',
    '.main-image img',
    '#product-image img',
    '.product img[src]'
  ].freeze

  # Platform detection patterns
  PLATFORM_PATTERNS = {
    amazon: [
      /amazon\./i,
      /images-amazon\.com/,
      /media-amazon\.com/,
      /ssl-images-amazon/
    ],
    mercadolivre: [
      /mercadolivre/i,
      /mercadolibre/i,
      /mlstatic\.com/,
      /meli-/
    ],
    shopify: [
      /cdn\.shopify\.com/,
      /myshopify\.com/,
      /Shopify\.theme/,
      /shopify-features/
    ],
    nuvemshop: [
      /nuvemshop/i,
      /nuvem\.com\.br/,
      /tiendanube/i
    ],
    magazineluiza: [
      /magazineluiza/i,
      /magalu/i,
      /mlcdn\.com\.br/
    ],
    nike: [
      /nike\.com/i,
      /nike-assets/,
      /static\.nike/
    ],
    adidas: [
      /adidas\./i,
      /adidas-group/,
      /assets\.adidas/
    ],
    on_running: [
      /on-running/i,
      /on\.com/,
      /on-running\.com/
    ],
    sephora: [
      /sephora\./i,
      /sephorastatic/,
      /sephora-img/
    ],
    woocommerce: [
      /woocommerce/i,
      /wp-content\/plugins\/woocommerce/
    ],
    magento: [
      /Magento/,
      /mage\//,
      /static\/version/
    ],
    bigcommerce: [
      /bigcommerce/i,
      /cdn\d+\.bigcommerce/
    ],
    squarespace: [
      /squarespace\.com/,
      /static\.squarespace/
    ],
    wix: [
      /wixstatic\.com/,
      /wix\.com/
    ],
    vtex: [
      /vteximg\.com/,
      /vtex/i
    ],
    salesforce_commerce: [
      /salesforce\.com/,
      /demandware\./
    ]
  }.freeze

  def extract
    return {} if @url.blank?

    begin
      uri = URI.parse(@url)
      return {} unless %w[http https].include?(uri.scheme)
      return {} unless safe_url?(uri)

      response = fetch_with_redirects(uri)
      return {} unless response.is_a?(Net::HTTPSuccess)

      html = response.body
      doc = Nokogiri::HTML(html)

      # Detect platform for optimized extraction
      platform = detect_platform(html)

      # Extract metadata with enhanced methods
      extract_with_fallbacks(doc, html, platform)

      @metadata
    rescue => e
      Rails.logger.warn "Enhanced URL metadata extraction failed for #{@url}: #{e.message}"
      {}
    end
  end

  private

  def detect_platform(html)
    PLATFORM_PATTERNS.each do |platform, patterns|
      patterns.each do |pattern|
        return platform if html.match?(pattern)
      end
    end
    :unknown
  end

  def extract_with_fallbacks(doc, html, platform)
    # Try standard extraction first
    extract_title_enhanced(doc, platform)
    extract_description(doc)
    extract_image_enhanced(doc, platform)
    extract_price_enhanced(doc, html, platform)
    extract_currency_enhanced(doc, html)
    extract_open_graph_data(doc)
    extract_json_ld_data(doc)

    # Apply platform-specific enhancements
    apply_platform_specific_extraction(doc, platform) if platform != :unknown

    # Final fallback for critical fields
    apply_intelligent_fallbacks(doc, html)
  end

  def extract_title_enhanced(doc, platform)
    # Try each selector in order
    TITLE_SELECTORS.each do |selector|
      element = doc.css(selector).first
      if element
        title = element['content'] || element.text.strip
        if title.present? && title.length > 5
          @metadata[:title] = clean_title(title)
          return
        end
      end
    end
  end

  def extract_image_enhanced(doc, platform)
    # Try each selector in order
    IMAGE_SELECTORS.each do |selector|
      element = doc.css(selector).first
      if element
        image = element['content'] || element['src'] || element['data-src']
        if image.present?
          @metadata[:image] = normalize_image_url(image)
          return
        end
      end
    end

    # Fallback: find largest image on page
    find_largest_image(doc)
  end

  def extract_price_enhanced(doc, html, platform)
    # Try structured data first
    price = extract_price_from_structured_data(doc)
    if price
      @metadata[:price] = price
      return
    end

    # Try selectors
    PRICE_SELECTORS.each do |selector|
      elements = doc.css(selector)
      elements.each do |element|
        price_text = element['content'] ||
                    element['data-price'] ||
                    element['data-price-amount'] ||
                    element.text

        price = extract_price_from_text(price_text)
        if price && price > 0
          @metadata[:price] = price
          return
        end
      end
    end

    # Advanced: Look for price patterns in JavaScript
    extract_price_from_javascript(html)
  end

  def extract_currency_enhanced(doc, html)
    # Try meta tags first
    currency_meta = doc.css('meta[property="product:price:currency"], meta[itemprop="priceCurrency"]').first
    if currency_meta
      currency = currency_meta['content']
      if currency && WishlistItem::CURRENCIES.key?(currency.upcase)
        @metadata[:currency] = currency.upcase
        return
      end
    end

    # Check for currency in data attributes
    currency_element = doc.css('[data-currency], [data-price-currency]').first
    if currency_element
      currency = currency_element['data-currency'] || currency_element['data-price-currency']
      if currency && WishlistItem::CURRENCIES.key?(currency.upcase)
        @metadata[:currency] = currency.upcase
        return
      end
    end

    # Fallback to existing methods
    super(doc, html)
  end

  def extract_price_from_structured_data(doc)
    # Look for microdata
    offer_element = doc.css('[itemtype*="schema.org/Offer"]').first
    if offer_element
      price_element = offer_element.css('[itemprop="price"]').first
      if price_element
        price_text = price_element['content'] || price_element.text
        return extract_price_from_text(price_text)
      end
    end

    nil
  end

  def extract_price_from_javascript(html)
    # Look for price in common JavaScript patterns
    patterns = [
      /"price":\s*"?([0-9.,]+)"?/,
      /"amount":\s*"?([0-9.,]+)"?/,
      /"salePrice":\s*"?([0-9.,]+)"?/,
      /productPrice['"]\s*:\s*"?([0-9.,]+)"?/,
      /dataLayer\.push.*price['"]\s*:\s*"?([0-9.,]+)"?/
    ]

    patterns.each do |pattern|
      match = html.match(pattern)
      if match
        price = extract_price_from_text(match[1])
        if price && price > 0
          @metadata[:price] = price
          return
        end
      end
    end
  end

  def apply_platform_specific_extraction(doc, platform)
    case platform
    when :amazon
      extract_amazon_specific(doc)
    when :mercadolivre
      extract_mercadolivre_specific(doc)
    when :shopify
      extract_shopify_specific(doc)
    when :nuvemshop
      extract_nuvemshop_specific(doc)
    when :magazineluiza
      extract_magazineluiza_specific(doc)
    when :nike
      extract_nike_specific(doc)
    when :adidas
      extract_adidas_specific(doc)
    when :on_running
      extract_on_running_specific(doc)
    when :sephora
      extract_sephora_specific(doc)
    when :woocommerce
      extract_woocommerce_specific(doc)
    when :magento
      extract_magento_specific(doc)
    end
  end

  def extract_shopify_specific(doc)
    # Shopify-specific meta tags
    shopify_price = doc.css('meta[property="product:price:amount"]').first
    @metadata[:price] ||= extract_price_from_text(shopify_price['content']) if shopify_price

    # Shopify product JSON
    scripts = doc.css('script[type="application/json"]')
    scripts.each do |script|
      next unless script.content.include?('"product"')
      begin
        data = JSON.parse(script.content)
        if data['product']
          @metadata[:title] ||= data['product']['title']
          @metadata[:description] ||= data['product']['description']
          if data['product']['variants']&.first
            variant = data['product']['variants'].first
            @metadata[:price] ||= variant['price'].to_f / 100 if variant['price']
          end
        end
      rescue JSON::ParserError
        next
      end
    end
  end

  def extract_woocommerce_specific(doc)
    # WooCommerce specific selectors
    price = doc.css('.woocommerce-Price-amount bdi').first
    @metadata[:price] ||= extract_price_from_text(price.text) if price

    # WooCommerce structured data
    doc.css('script[type="application/ld+json"]').each do |script|
      begin
        data = JSON.parse(script.content)
        if data['@type'] == 'Product'
          @metadata[:title] ||= data['name']
          @metadata[:description] ||= data['description']
        end
      rescue JSON::ParserError
        next
      end
    end
  end

  def extract_magento_specific(doc)
    # Magento specific patterns
    price_box = doc.css('.price-box[data-price-box]').first
    if price_box
      price_element = price_box.css('[data-price-type="finalPrice"]').first
      @metadata[:price] ||= extract_price_from_text(price_element['data-price-amount']) if price_element
    end
  end

  def extract_amazon_specific(doc)
    # Amazon specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('#priceblock_dealprice, #priceblock_ourprice, #priceblock_saleprice, .a-price-whole, .a-price.a-text-price.a-size-medium.apexPriceToPay, .a-price-range').first&.text)
    @metadata[:title] ||= doc.css('#productTitle, h1.a-size-large').first&.text&.strip

    # Amazon often has the main image in a specific container
    image = doc.css('#landingImage, #imgBlkFront, #ebooksImgBlkFront, .imgTagWrapper img').first
    @metadata[:image] ||= image['src'] || image['data-old-hires'] || image['data-a-dynamic-image']&.scan(/"(https?:\/\/[^"]+)"/).first&.first if image

    # Amazon availability
    availability = doc.css('#availability span, .a-size-medium.a-color-success').first
    @metadata[:availability] = availability.text.strip if availability
  end

  def extract_mercadolivre_specific(doc)
    # Mercado Livre/Libre specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('.andes-money-amount__fraction, .price-tag-fraction, .ui-pdp-price__second-line .andes-money-amount').first&.text)
    @metadata[:title] ||= doc.css('.ui-pdp-title, h1.item-title__primary').first&.text&.strip
    @metadata[:currency] ||= doc.css('.andes-money-amount__currency-symbol').first&.text&.include?('R$') ? 'BRL' : 'USD'

    # ML images
    image = doc.css('.ui-pdp-image, .gallery-image-container img, figure.ui-pdp-gallery__figure img').first
    @metadata[:image] ||= image['src'] || image['data-src'] || image['data-zoom'] if image
  end

  def extract_nuvemshop_specific(doc)
    # NuvemShop/TiendaNube specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('.js-price-display, .product-price, .price').first&.text)
    @metadata[:title] ||= doc.css('.product-name, h1[itemprop="name"], .js-product-name').first&.text&.strip

    # NuvemShop structured data
    doc.css('script[type="application/ld+json"]').each do |script|
      begin
        data = JSON.parse(script.content)
        if data['@type'] == 'Product'
          @metadata[:title] ||= data['name']
          @metadata[:price] ||= data['offers']&.dig('price')
          @metadata[:currency] ||= data['offers']&.dig('priceCurrency')
        end
      rescue JSON::ParserError
        next
      end
    end
  end

  def extract_magazineluiza_specific(doc)
    # Magazine Luiza specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('[data-testid="price-value"], .price-template__text, .product-price__value').first&.text)
    @metadata[:title] ||= doc.css('[data-testid="product-title"], h1.header-product__title').first&.text&.strip
    @metadata[:currency] = 'BRL' # Magazine Luiza is Brazil only

    # Magalu images
    image = doc.css('[data-testid="image-gallery-product"] img, .product-image__container img').first
    @metadata[:image] ||= image['src'] if image
  end

  def extract_nike_specific(doc)
    # Nike specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('.product-price, .css-b9fpep, .css-1emn094, [data-test="product-price"]').first&.text)
    @metadata[:title] ||= doc.css('#pdp_product_title, h1[data-test="product-title"], .product-info h1').first&.text&.strip

    # Nike images
    image = doc.css('.css-viwop1 img, .hero-image img, picture.css-1vqt2wc img').first
    @metadata[:image] ||= image['src'] if image

    # Nike color/style
    @metadata[:color] = doc.css('.description-preview__color-description').first&.text&.strip
  end

  def extract_adidas_specific(doc)
    # Adidas specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('.gl-price-item, .product-price, [data-auto-id="product-price"]').first&.text)
    @metadata[:title] ||= doc.css('[data-auto-id="product-title"], h1.product_title, .product-name').first&.text&.strip

    # Adidas images
    image = doc.css('.product-image img, [data-auto-id="image-carousel"] img').first
    @metadata[:image] ||= image['src'] || image['data-src'] if image

    # Adidas product code
    @metadata[:product_code] = doc.css('.product-code, [data-auto-id="product-color-sku"]').first&.text&.strip
  end

  def extract_on_running_specific(doc)
    # On Running specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('.price-sales, .product-price__price, .price').first&.text)
    @metadata[:title] ||= doc.css('.product-name, h1.product-detail__name').first&.text&.strip

    # On Running images
    image = doc.css('.product-image-main img, .product-detail__hero-image img').first
    @metadata[:image] ||= image['src'] || image['data-src'] if image

    # On Running technology/features
    @metadata[:technology] = doc.css('.product-technology').first&.text&.strip
  end

  def extract_sephora_specific(doc)
    # Sephora specific selectors
    @metadata[:price] ||= extract_price_from_text(doc.css('.css-1k0oecy, .css-18suhml, [data-comp="Price "]').first&.text)
    @metadata[:title] ||= doc.css('[data-comp="ProductName "], h1.css-1g2jq23, .product-name').first&.text&.strip

    # Sephora brand
    @metadata[:brand] = doc.css('[data-comp="ProductBrand "], .css-euydo4').first&.text&.strip

    # Sephora images
    image = doc.css('[data-comp="ProductImage "] img, .css-1rovmyu img').first
    @metadata[:image] ||= image['src'] if image

    # Sephora rating
    rating = doc.css('[data-comp="ProductRating "], .css-1j53ife').first
    @metadata[:rating] = rating['aria-label'] if rating
  end

  def apply_intelligent_fallbacks(doc, html)
    # If no title found, try to extract from URL or breadcrumbs
    if @metadata[:title].blank?
      breadcrumb = doc.css('[itemtype*="BreadcrumbList"] [itemprop="name"]').last
      @metadata[:title] = breadcrumb.text.strip if breadcrumb
    end

    # If no image found, look for any product image
    if @metadata[:image].blank?
      images = doc.css('img[alt*="product"], img[alt*="Product"], img[title*="product"]')
      if images.any?
        @metadata[:image] = normalize_image_url(images.first['src'] || images.first['data-src'])
      end
    end

    # If no price found, look for any number that looks like a price
    if @metadata[:price].blank?
      price_pattern = /(?:[$£€¥₹R\$]\s*)?(\d{1,6}(?:[.,]\d{2})?)/
      matches = html.scan(price_pattern)
      if matches.any?
        prices = matches.map { |m| extract_price_from_text(m[0]) }.compact.select { |p| p > 0 && p < 100000 }
        @metadata[:price] = prices.min if prices.any?
      end
    end
  end

  def find_largest_image(doc)
    images = doc.css('img[src], img[data-src]')
    largest = nil
    largest_size = 0

    images.each do |img|
      width = img['width'].to_i
      height = img['height'].to_i
      size = width * height

      if size > largest_size && !img['src'].to_s.include?('logo') && !img['src'].to_s.include?('icon')
        largest = img
        largest_size = size
      end
    end

    if largest
      @metadata[:image] = normalize_image_url(largest['src'] || largest['data-src'])
    end
  end

  def normalize_image_url(image_url)
    return nil if image_url.blank?

    # Handle protocol-relative URLs
    image_url = "https:#{image_url}" if image_url.start_with?('//')

    # Handle relative URLs
    unless image_url.start_with?('http')
      uri = URI.parse(@url)
      base = "#{uri.scheme}://#{uri.host}"
      image_url = image_url.start_with?('/') ? "#{base}#{image_url}" : "#{base}/#{image_url}"
    end

    image_url
  end

  def clean_title(title)
    # Remove common suffixes and clean up
    title.gsub(/\s*[\|\-–—]\s*.*(Shop|Store|Buy|Purchase|Sale).*$/i, '')
         .gsub(/\s+/, ' ')
         .strip
  end
end