module ShareHelper
  def share_buttons(title, url, description = nil, image_url = nil)
    description ||= t('common.share.default_description')
    image_url ||= "#{request.base_url}/wishare-og-image.png"
    
    content_tag :div, class: "flex flex-wrap items-center gap-2" do
      safe_join([
        whatsapp_share_button(title, url),
        twitter_share_button(title, url, description),
        facebook_share_button(url),
        linkedin_share_button(title, url, description),
        telegram_share_button(title, url, description),
        copy_link_button(url)
      ])
    end
  end

  def whatsapp_share_button(title, url)
    text = "#{title} - #{url}"
    whatsapp_url = "https://wa.me/?text=#{CGI.escape(text)}"
    
    link_to whatsapp_url, 
            target: "_blank", 
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 px-3 py-2 bg-green-500 hover:bg-green-600 text-white text-sm rounded-lg transition duration-200 cursor-pointer",
            title: t('common.share.whatsapp') do
      safe_join([
        content_tag(:span, "📱", class: "text-base"),
        content_tag(:span, "WhatsApp", class: "hidden sm:inline")
      ])
    end
  end

  def twitter_share_button(title, url, description = nil)
    text = description ? "#{title} - #{description}" : title
    twitter_url = "https://twitter.com/intent/tweet?text=#{CGI.escape(text)}&url=#{CGI.escape(url)}"
    
    link_to twitter_url, 
            target: "_blank", 
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 px-3 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm rounded-lg transition duration-200 cursor-pointer",
            title: t('common.share.twitter') do
      safe_join([
        content_tag(:span, "🐦", class: "text-base"),
        content_tag(:span, "Twitter", class: "hidden sm:inline")
      ])
    end
  end

  def facebook_share_button(url)
    facebook_url = "https://www.facebook.com/sharer/sharer.php?u=#{CGI.escape(url)}"
    
    link_to facebook_url, 
            target: "_blank", 
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-lg transition duration-200 cursor-pointer",
            title: t('common.share.facebook') do
      safe_join([
        content_tag(:span, "📘", class: "text-base"),
        content_tag(:span, "Facebook", class: "hidden sm:inline")
      ])
    end
  end

  def linkedin_share_button(title, url, description = nil)
    linkedin_url = "https://www.linkedin.com/sharing/share-offsite/?url=#{CGI.escape(url)}"
    
    link_to linkedin_url, 
            target: "_blank", 
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 px-3 py-2 bg-blue-700 hover:bg-blue-800 text-white text-sm rounded-lg transition duration-200 cursor-pointer",
            title: t('common.share.linkedin') do
      safe_join([
        content_tag(:span, "💼", class: "text-base"),
        content_tag(:span, "LinkedIn", class: "hidden sm:inline")
      ])
    end
  end

  def telegram_share_button(title, url, description = nil)
    text = description ? "#{title}\n\n#{description}" : title
    telegram_url = "https://t.me/share/url?url=#{CGI.escape(url)}&text=#{CGI.escape(text)}"
    
    link_to telegram_url, 
            target: "_blank", 
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-1 px-3 py-2 bg-blue-400 hover:bg-blue-500 text-white text-sm rounded-lg transition duration-200 cursor-pointer",
            title: t('common.share.telegram') do
      safe_join([
        content_tag(:span, "✈️", class: "text-base"),
        content_tag(:span, "Telegram", class: "hidden sm:inline")
      ])
    end
  end

  def copy_link_button(url)
    button_tag type: "button", 
               class: "inline-flex items-center gap-1 px-3 py-2 bg-gray-600 dark:bg-gray-700 hover:bg-gray-700 dark:hover:bg-gray-600 text-white text-sm rounded-lg transition duration-200 cursor-pointer",
               title: t('common.share.copy_link'),
               data: { 
                 controller: "clipboard",
                 clipboard_text_value: url,
                 action: "click->clipboard#copy"
               } do
      safe_join([
        content_tag(:span, "🔗", class: "text-base"),
        content_tag(:span, t('common.share.copy'), class: "hidden sm:inline")
      ])
    end
  end

  def share_modal_button(title, url, description = nil, button_text = nil, button_class = nil)
    button_text ||= t('common.share.button')
    button_class ||= "inline-flex items-center gap-2 px-4 py-2 bg-rose-500 hover:bg-rose-600 text-white rounded-lg transition duration-200 cursor-pointer"
    
    button_tag type: "button",
               class: button_class,
               data: {
                 controller: "share-modal",
                 action: "click->share-modal#open",
                 share_modal_title_value: title,
                 share_modal_url_value: url,
                 share_modal_description_value: description || t('common.share.default_description')
               } do
      safe_join([
        content_tag(:svg, class: "w-4 h-4", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.367 2.684 3 3 0 00-5.367-2.684z")
        end,
        content_tag(:span, button_text)
      ])
    end
  end
end