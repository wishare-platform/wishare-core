module SeoHelper
  def seo_title(title = nil)
    return @seo_title if @seo_title && title.nil?
    
    base_title = "Wishare - Share Wishlists with Friends & Family"
    @seo_title = title ? "#{title} | Wishare" : base_title
  end

  def seo_description(description = nil)
    return @seo_description if @seo_description && description.nil?
    
    default_description = "Create and share wishlists with friends and family. Perfect for birthdays, holidays, and special occasions. Make gifting meaningful with Wishare."
    @seo_description = description || default_description
  end

  def seo_keywords(additional_keywords = [])
    base_keywords = %w[
      wishlist gifts birthday holiday gift-sharing family
      present-ideas gift-registry occasions thoughtful-giving
    ]
    
    (base_keywords + Array(additional_keywords)).join(', ')
  end

  def seo_image_url(image_path = nil)
    image_path ||= '/wishare-og-image.png'
    "#{request.base_url}#{image_path}"
  end

  def structured_data_website
    {
      "@context" => "https://schema.org",
      "@type" => "WebApplication",
      "name" => "Wishare",
      "description" => seo_description,
      "url" => request.base_url,
      "applicationCategory" => "LifestyleApplication",
      "operatingSystem" => "Web",
      "offers" => {
        "@type" => "Offer",
        "price" => "0",
        "priceCurrency" => "USD"
      },
      "author" => {
        "@type" => "Organization",
        "name" => "Wishare",
        "url" => request.base_url
      }
    }.to_json
  end

  def structured_data_wishlist(wishlist)
    return unless wishlist

    {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => wishlist.name,
      "description" => wishlist.description,
      "numberOfItems" => wishlist.wishlist_items.count,
      "itemListElement" => wishlist.wishlist_items.limit(10).map.with_index do |item, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "item" => {
            "@type" => "Product",
            "name" => item.name,
            "description" => item.description,
            "offers" => item.price.present? ? {
              "@type" => "Offer",
              "price" => item.price.to_f,
              "priceCurrency" => "USD"
            } : nil
          }.compact
        }
      end
    }.to_json
  end
end