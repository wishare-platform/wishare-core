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
              "priceCurrency" => item.currency || "USD"
            } : nil
          }.compact
        }
      end
    }.to_json
  end

  def structured_data_user(user)
    return unless user

    {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => user.name,
      "url" => user_url(user),
      "image" => user.profile_avatar_url || seo_image_url,
      "description" => user.bio.present? && user.can_view_bio?(current_user) ? user.bio : nil,
      "sameAs" => user.has_social_presence? && user.can_view_social_links?(current_user) ?
        user.social_links.values.compact : nil
    }.compact.to_json
  end

  def user_meta_title(user)
    "#{user.display_name}'s Profile | Wishare"
  end

  def user_meta_description(user)
    if user.bio.present? && user.can_view_bio?(current_user)
      bio_preview = user.bio.truncate(150)
      "#{bio_preview} | View #{user.display_name}'s wishlists and connect on Wishare"
    else
      "View #{user.display_name}'s wishlists on Wishare. Create and share wishlists for birthdays, holidays, and special occasions."
    end
  end

  def wishlist_meta_title(wishlist)
    "#{wishlist.name} by #{wishlist.user.display_name} | Wishare"
  end

  def wishlist_meta_description(wishlist)
    description = wishlist.description.present? ? wishlist.description.truncate(100) : ""
    item_text = wishlist.wishlist_items.count == 1 ? "1 item" : "#{wishlist.wishlist_items.count} items"
    event_text = wishlist.event_type.present? ? "Perfect for #{wishlist.event_type.humanize}" : ""

    parts = [description, item_text, event_text].reject(&:blank?)
    "#{parts.join(' • ')} | Share wishlists on Wishare"
  end

  def wishlist_item_meta_title(item)
    "#{item.name} from #{item.wishlist.user.display_name}'s #{item.wishlist.name} | Wishare"
  end

  def wishlist_item_meta_description(item)
    description = item.description.present? ? item.description.truncate(100) : item.name
    price_text = item.price.present? ? "#{item.formatted_price}" : "Price not specified"

    "#{description} • #{price_text} | Add to your wishlist on Wishare"
  end

  def meta_image_url(object = nil)
    case object
    when User
      object.profile_avatar_url || seo_image_url
    when Wishlist
      if object.cover_image.attached?
        rails_blob_url(object.cover_image)
      else
        seo_image_url
      end
    when WishlistItem
      if object.image_url.present?
        object.image_url
      elsif object.wishlist.cover_image.attached?
        rails_blob_url(object.wishlist.cover_image)
      else
        seo_image_url
      end
    else
      seo_image_url
    end
  end
end