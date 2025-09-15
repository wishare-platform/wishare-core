module DashboardHelper
  def welcome_subtitle
    hour = Time.current.hour
    case hour
    when 5..11
      t('dashboard.subtitle.morning')
    when 12..17
      t('dashboard.subtitle.afternoon')
    when 18..23, 0..4
      t('dashboard.subtitle.evening')
    else
      t('dashboard.subtitle.default')
    end
  end

  def contextual_message(user)
    if user.created_at > 1.week.ago
      t('dashboard.context.first_visit')
    elsif user.notifications.unread.any?
      t('dashboard.context.new_notifications', count: user.notifications.unread.count)
    elsif upcoming_events_count(user) > 0
      t('dashboard.context.active_events', count: upcoming_events_count(user))
    else
      t('dashboard.context.returning_user')
    end
  end

  def time_ago_in_context(time)
    distance = Time.current - time
    case distance
    when 0..1.hour
      if distance < 5.minutes
        t('dashboard.time.just_now')
      else
        t('dashboard.time.minutes_ago', count: (distance / 1.minute).round)
      end
    when 1.hour..1.day
      t('dashboard.time.hours_ago', count: (distance / 1.hour).round)
    else
      time_ago_in_words(time)
    end
  end

  def event_type_with_icon(event_type)
    case event_type&.downcase
    when 'birthday'
      t('dashboard.events.birthday')
    when 'wedding'
      t('dashboard.events.wedding')
    when 'anniversary'
      t('dashboard.events.anniversary')
    when 'baby_shower'
      t('dashboard.events.baby_shower')
    when 'graduation'
      t('dashboard.events.graduation')
    when 'christmas'
      t('dashboard.events.christmas')
    when 'valentines'
      t('dashboard.events.valentines')
    when 'mothers_day'
      t('dashboard.events.mothers_day')
    when 'fathers_day'
      t('dashboard.events.fathers_day')
    else
      t('dashboard.events.other')
    end
  end

  def days_until_event(event_date)
    return nil unless event_date

    days = (event_date.to_date - Date.current).to_i

    case days
    when 0
      t('dashboard.time.today')
    when 1
      t('dashboard.time.tomorrow')
    else
      t('dashboard.time.days_away', count: days)
    end
  end

  def user_avatar_or_initials(user, size: 'w-12 h-12')
    avatar_url = user.profile_avatar_url

    if avatar_url.present?
      image_tag avatar_url,
                class: "#{size} rounded-full object-cover",
                alt: "#{user.name}'s avatar"
    else
      content_tag :div,
                  class: "#{size} rounded-full bg-pink-500 flex items-center justify-center text-white font-semibold" do
        user.name.split(' ').map(&:first).join('').upcase
      end
    end
  end

  def wishlist_cover_or_placeholder(wishlist, size: 'aspect-video')
    cover_url = wishlist.cover_image_url

    if cover_url.present?
      image_tag cover_url,
                class: "w-full #{size} object-cover rounded-lg",
                alt: "#{wishlist.name} cover"
    else
      content_tag :div,
                  class: "w-full #{size} bg-gradient-to-br from-pink-400 to-purple-500 rounded-lg flex items-center justify-center" do
        content_tag :span,
                    wishlist.name.first.upcase,
                    class: "text-white text-2xl font-bold"
      end
    end
  end

  def format_currency_for_dashboard(amount, currency = 'USD')
    return '—' if amount.nil?

    number_to_currency(amount, unit: currency_symbol(currency), precision: 0)
  end

  def currency_symbol(currency)
    case currency.upcase
    when 'USD' then '$'
    when 'EUR' then '€'
    when 'GBP' then '£'
    when 'BRL' then 'R$'
    when 'CAD' then 'C$'
    when 'AUD' then 'A$'
    when 'JPY' then '¥'
    else currency
    end
  end

  def truncate_for_card(text, length: 50)
    truncate(text, length: length, separator: ' ')
  end

  def privacy_badge(visibility)
    case visibility
    when 'public'
      content_tag :span, t('dashboard.wishlists.privacy_public'),
                  class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100"
    when 'friends'
      content_tag :span, t('dashboard.wishlists.privacy_friends'),
                  class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-800 dark:text-blue-100"
    when 'private'
      content_tag :span, t('dashboard.wishlists.privacy_private'),
                  class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-100"
    end
  end

  private

  def upcoming_events_count(user)
    # Cache this count for performance
    Rails.cache.fetch("upcoming_events_count_#{user.id}", expires_in: 1.hour) do
      user.wishlists.where('event_date >= ? AND event_date <= ?', Date.current, 30.days.from_now).count
    end
  end
end
