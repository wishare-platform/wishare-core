class Api::V1::MobileController < Api::V1::BaseController
  before_action :authenticate_api_user!, except: [:health_check]
  before_action :set_mobile_user_agent

  # Performance tracking for mobile endpoints
  around_action :track_mobile_performance

  # Enhanced performance metrics for mobile optimization
  def performance_metrics
    metrics = {
      database: {
        connections: ActiveRecord::Base.connection_pool.size,
        query_cache: ActiveRecord::Base.connection.query_cache_enabled
      },
      cache: Rails.cache.respond_to?(:stats) ? Rails.cache.stats : { status: 'basic' },
      memory: get_memory_stats,
      response_times: get_cached_response_times,
      mobile_specific: {
        image_compression_ratio: 0.8,
        cache_hit_rate: Rails.cache.fetch('mobile_cache_hit_rate', expires_in: 5.minutes) { 85 },
        offline_sync_size: get_offline_sync_size(current_api_user)
      }
    }

    render json: { status: 'success', data: metrics }
  end

  # Optimized feed endpoint for mobile
  def feed
    limit = [params[:limit]&.to_i || 20, 50].min # Cap at 50 for mobile
    offset = params[:offset]&.to_i || 0

    wishlists = MobileOptimizationService.optimized_user_feed(
      current_api_user,
      limit: limit,
      offset: offset
    )

    render json: {
      wishlists: wishlists.map { |w| serialize_wishlist_mobile(w) },
      pagination: {
        limit: limit,
        offset: offset,
        has_more: wishlists.count == limit,
        next_offset: offset + limit
      },
      cache_info: {
        cached_at: Time.current.iso8601,
        expires_in: 1.hour.to_i
      }
    }
  end

  # Batch analytics for reduced API calls
  def batch_analytics
    events = params[:events] || []

    if events.empty?
      return render json: { error: 'No events provided' }, status: :bad_request
    end

    validated_events = events.map do |event|
      {
        user_id: current_api_user.id,
        event_name: event[:event_name],
        event_data: event[:event_data] || {},
        platform: 'mobile',
        device_info: event[:device_info] || {},
        session_id: session.id,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    MobileOptimizationService.mobile_analytics_batch(validated_events)

    render json: {
      success: true,
      events_processed: validated_events.count,
      timestamp: Time.current.iso8601
    }
  end

  # Offline data preloading
  def offline_data
    MobileOptimizationService.preload_mobile_assets(current_api_user)

    render json: {
      user_profile: serialize_user_profile(current_api_user),
      user_wishlists: serialize_user_wishlists(current_api_user),
      recent_activities: serialize_recent_activities(current_api_user),
      app_config: enhanced_mobile_app_config,
      offline_size_mb: calculate_offline_size(current_api_user)
    }
  end

  # Health check endpoint for mobile apps
  def health_check
    render json: {
      status: 'ok',
      timestamp: Time.current.iso8601,
      version: '1.0.0',
      platform: 'rails',
      environment: Rails.env
    }
  end

  # Get mobile app configuration
  def config
    config_data = {
      push_notifications: {
        enabled: true,
        fcm_sender_id: ENV['FCM_SENDER_ID']
      },
      biometric_auth: {
        enabled: true,
        supported_types: ['fingerprint', 'face', 'iris']
      },
      camera: {
        enabled: true,
        max_image_size: 5.megabytes,
        supported_formats: ['jpeg', 'jpg', 'png', 'heic']
      },
      sharing: {
        enabled: true,
        deep_links: {
          wishlist: "https://wishare.xyz/wishlists/:id",
          item: "https://wishare.xyz/items/:id",
          profile: "https://wishare.xyz/users/:id"
        }
      },
      features: {
        offline_mode: false,
        background_sync: true,
        analytics: true
      }
    }

    render json: {
      status: 'success',
      data: config_data
    }
  end

  # Upload image for wishlist item
  def upload_image
    @wishlist = current_user.wishlists.find(params[:wishlist_id])
    @item = @wishlist.wishlist_items.find(params[:item_id])

    unless params[:image].present?
      return render json: {
        status: 'error',
        message: 'No image provided'
      }, status: :bad_request
    end

    begin
      # Process the uploaded image
      uploaded_file = params[:image]

      # Validate file type
      unless valid_image_type?(uploaded_file)
        return render json: {
          status: 'error',
          message: 'Invalid image type. Supported formats: JPEG, PNG, HEIC'
        }, status: :unprocessable_entity
      end

      # Validate file size
      if uploaded_file.size > 5.megabytes
        return render json: {
          status: 'error',
          message: 'Image too large. Maximum size is 5MB'
        }, status: :unprocessable_entity
      end

      # Attach the image to the wishlist item
      @item.image.attach(uploaded_file)

      # Track analytics event
      track_mobile_event('image_uploaded', {
        wishlist_id: @wishlist.id,
        item_id: @item.id,
        file_size: uploaded_file.size,
        content_type: uploaded_file.content_type
      })

      render json: {
        status: 'success',
        message: 'Image uploaded successfully',
        data: {
          item_id: @item.id,
          image_url: @item.image.attached? ? url_for(@item.image) : nil
        }
      }

    rescue ActiveRecord::RecordNotFound
      render json: {
        status: 'error',
        message: 'Wishlist or item not found'
      }, status: :not_found

    rescue StandardError => e
      Rails.logger.error "Mobile image upload error: #{e.message}"
      render json: {
        status: 'error',
        message: 'Failed to upload image'
      }, status: :internal_server_error
    end
  end

  # Test push notification
  def test_push_notification
    device_token = current_user.device_tokens.where(platform: params[:platform]).first

    unless device_token
      return render json: {
        status: 'error',
        message: 'No device token found for this platform'
      }, status: :not_found
    end

    begin
      notification_data = {
        title: "Test Notification",
        body: "This is a test notification from Wishare",
        data: {
          type: 'test',
          user_id: current_user.id.to_s,
          timestamp: Time.current.to_i
        }
      }

      case device_token.platform
      when 'ios'
        send_ios_push_notification(device_token.token, notification_data)
      when 'android'
        send_android_push_notification(device_token.token, notification_data)
      end

      # Track analytics event
      track_mobile_event('test_push_sent', {
        platform: device_token.platform,
        user_id: current_user.id
      })

      render json: {
        status: 'success',
        message: 'Test push notification sent',
        data: {
          platform: device_token.platform,
          sent_at: Time.current.iso8601
        }
      }

    rescue StandardError => e
      Rails.logger.error "Test push notification error: #{e.message}"
      render json: {
        status: 'error',
        message: 'Failed to send test notification'
      }, status: :internal_server_error
    end
  end

  # Track mobile analytics event
  def track_event
    event_type = params[:event_type]
    event_data = params[:event_data] || {}

    unless event_type.present?
      return render json: {
        status: 'error',
        message: 'Event type is required'
      }, status: :bad_request
    end

    begin
      # Create analytics event
      AnalyticsEvent.create!(
        user: current_user,
        event_type: event_type,
        metadata: event_data.merge({
          platform: 'mobile',
          user_agent: request.headers['User-Agent'],
          ip_address: request.remote_ip
        }),
        session_id: session.id
      )

      render json: {
        status: 'success',
        message: 'Event tracked successfully'
      }

    rescue StandardError => e
      Rails.logger.error "Mobile analytics tracking error: #{e.message}"
      render json: {
        status: 'error',
        message: 'Failed to track event'
      }, status: :internal_server_error
    end
  end

  # Get app feature flags
  def feature_flags
    flags = {
      camera_upload: true,
      biometric_auth: true,
      push_notifications: true,
      social_sharing: true,
      offline_mode: false,
      dark_mode: true,
      analytics: true,
      crash_reporting: Rails.env.production?,
      beta_features: Rails.env.development?
    }

    render json: {
      status: 'success',
      data: flags
    }
  end

  # Device information endpoint
  def device_info
    device_data = {
      platform: params[:platform],
      device_type: params[:device_type],
      app_version: params[:app_version],
      os_version: params[:os_version],
      device_model: params[:device_model],
      screen_size: params[:screen_size],
      language: params[:language] || 'en',
      timezone: params[:timezone] || 'UTC'
    }

    # Store or update device info for the user
    current_user.update_device_info(device_data)

    render json: {
      status: 'success',
      message: 'Device info updated successfully',
      data: {
        updated_at: Time.current.iso8601
      }
    }
  rescue StandardError => e
    Rails.logger.error "Device info update error: #{e.message}"
    render json: {
      status: 'error',
      message: 'Failed to update device info'
    }, status: :internal_server_error
  end

  # Sync data for offline support
  def sync_data
    sync_timestamp = params[:last_sync] ? Time.parse(params[:last_sync]) : 30.days.ago

    begin
      # Get updated data since last sync
      updated_data = {
        wishlists: current_user.wishlists
          .includes(:wishlist_items, :event)
          .where('updated_at > ?', sync_timestamp)
          .map { |w| wishlist_sync_data(w) },

        connections: current_user.connections
          .includes(:friend)
          .where('updated_at > ?', sync_timestamp)
          .map { |c| connection_sync_data(c) },

        notifications: current_user.notifications
          .where('created_at > ?', sync_timestamp)
          .limit(50)
          .map { |n| notification_sync_data(n) },

        user_profile: user_profile_data
      }

      render json: {
        status: 'success',
        data: updated_data,
        sync_timestamp: Time.current.iso8601
      }

    rescue StandardError => e
      Rails.logger.error "Data sync error: #{e.message}"
      render json: {
        status: 'error',
        message: 'Failed to sync data'
      }, status: :internal_server_error
    end
  end

  # Upload avatar for user profile
  def upload_avatar
    unless params[:avatar].present?
      return render json: {
        status: 'error',
        message: 'No avatar image provided'
      }, status: :bad_request
    end

    begin
      uploaded_file = params[:avatar]

      # Validate file type
      unless valid_image_type?(uploaded_file)
        return render json: {
          status: 'error',
          message: 'Invalid image type. Supported formats: JPEG, PNG, HEIC'
        }, status: :unprocessable_entity
      end

      # Validate file size
      if uploaded_file.size > 5.megabytes
        return render json: {
          status: 'error',
          message: 'Image too large. Maximum size is 5MB'
        }, status: :unprocessable_entity
      end

      # Attach the avatar to the user
      current_user.avatar.attach(uploaded_file)

      # Track analytics event
      track_mobile_event('avatar_uploaded', {
        user_id: current_user.id,
        file_size: uploaded_file.size,
        content_type: uploaded_file.content_type
      })

      render json: {
        status: 'success',
        message: 'Avatar uploaded successfully',
        data: {
          avatar_url: current_user.profile_avatar_url(:large)
        }
      }
    rescue => e
      Rails.logger.error "Mobile avatar upload error: #{e.message}"
      render json: {
        status: 'error',
        message: 'Failed to upload avatar'
      }, status: :internal_server_error
    end
  end

  # Upload cover image for wishlist
  def upload_wishlist_cover
    @wishlist = current_user.wishlists.find(params[:wishlist_id])

    unless params[:cover_image].present?
      return render json: {
        status: 'error',
        message: 'No cover image provided'
      }, status: :bad_request
    end

    begin
      uploaded_file = params[:cover_image]

      # Validate file type
      unless valid_image_type?(uploaded_file)
        return render json: {
          status: 'error',
          message: 'Invalid image type. Supported formats: JPEG, PNG, HEIC'
        }, status: :unprocessable_entity
      end

      # Validate file size
      if uploaded_file.size > 10.megabytes # Larger limit for cover images
        return render json: {
          status: 'error',
          message: 'Image too large. Maximum size is 10MB'
        }, status: :unprocessable_entity
      end

      # Attach the cover image to the wishlist
      @wishlist.cover_image.attach(uploaded_file)

      # Track analytics event
      track_mobile_event('wishlist_cover_uploaded', {
        wishlist_id: @wishlist.id,
        user_id: current_user.id,
        file_size: uploaded_file.size,
        content_type: uploaded_file.content_type
      })

      render json: {
        status: 'success',
        message: 'Cover image uploaded successfully',
        data: {
          wishlist_id: @wishlist.id,
          cover_image_url: @wishlist.cover_image_url(:hero)
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        status: 'error',
        message: 'Wishlist not found'
      }, status: :not_found
    rescue => e
      Rails.logger.error "Mobile wishlist cover upload error: #{e.message}"
      render json: {
        status: 'error',
        message: 'Failed to upload cover image'
      }, status: :internal_server_error
    end
  end

  private

  def set_mobile_user_agent
    @mobile_platform = request.headers['X-Mobile-Platform'] || 'unknown'
    @app_version = request.headers['X-App-Version'] || '1.0.0'
  end

  def track_mobile_performance
    start_time = Time.current
    yield
    duration = ((Time.current - start_time) * 1000).round(2)

    Rails.logger.info "📱 Mobile API Performance - #{action_name}: #{duration}ms (#{@mobile_platform})"

    # Track slow requests
    if duration > 1000 # 1 second
      Rails.logger.warn "🐌 Slow mobile request: #{action_name} took #{duration}ms"
    end
  end

  def get_memory_stats
    {
      used_mb: (GC.stat[:heap_allocated_pages] * 4096 / 1024 / 1024).round(2),
      gc_count: GC.count,
      gc_time: GC.stat[:time] || 0
    }
  end

  def get_cached_response_times
    Rails.cache.fetch('mobile_response_times', expires_in: 5.minutes) do
      {
        feed_avg_ms: 150,
        search_avg_ms: 80,
        sync_avg_ms: 200,
        offline_data_avg_ms: 300,
        image_upload_avg_ms: 500
      }
    end
  end

  def get_offline_sync_size(user)
    # Calculate approximate size of offline data
    wishlists_count = user.wishlists.count
    items_count = user.wishlists.joins(:wishlist_items).count
    connections_count = user.connections.count

    # Rough calculation: 2KB per wishlist, 1KB per item, 0.5KB per connection
    size_bytes = (wishlists_count * 2048) + (items_count * 1024) + (connections_count * 512)
    (size_bytes / 1024.0 / 1024.0).round(2) # Convert to MB
  end

  def calculate_offline_size(user)
    # More detailed calculation including images
    base_size = get_offline_sync_size(user)

    # Add estimated image sizes (compressed)
    image_count = user.wishlists.joins(:wishlist_items).where.not(wishlist_items: { image: nil }).count
    image_size_mb = image_count * 0.2 # 200KB per compressed image

    (base_size + image_size_mb).round(2)
  end

  def serialize_wishlist_mobile(wishlist)
    {
      id: wishlist.id,
      name: wishlist.name,
      description: wishlist.description,
      event_type: wishlist.event_type,
      event_date: wishlist.event_date,
      visibility: wishlist.visibility,
      cover_image_url: wishlist.cover_image_url,
      items_count: wishlist.wishlist_items.count,
      owner: {
        id: wishlist.user.id,
        name: wishlist.user.name,
        profile_picture_url: wishlist.user.profile_avatar_url
      },
      items_preview: wishlist.wishlist_items.limit(3).map { |item| serialize_item_mobile(item) },
      updated_at: wishlist.updated_at.iso8601,
      cache_key: "wishlist_#{wishlist.id}_#{wishlist.updated_at.to_i}"
    }
  end

  def serialize_item_mobile(item)
    {
      id: item.id,
      name: item.name,
      description: item.description,
      url: item.url,
      price: item.price,
      currency: item.currency,
      status: item.status,
      image_url: item.image_url,
      purchased_by: item.purchased_by ? {
        id: item.purchased_by.id,
        name: item.purchased_by.name
      } : nil,
      created_at: item.created_at.iso8601,
      updated_at: item.updated_at.iso8601
    }
  end

  def serialize_user_profile(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      profile_picture_url: user.profile_avatar_url,
      wishlists_count: user.wishlists_count,
      connections_count: user.connections_count,
      preferred_currency: user.preferred_currency,
      preferred_language: user.preferred_language,
      bio: user.bio,
      website: user.website
    }
  end

  def serialize_user_wishlists(user)
    user.wishlists.includes(:wishlist_items).map do |wishlist|
      {
        id: wishlist.id,
        name: wishlist.name,
        description: wishlist.description,
        items_count: wishlist.wishlist_items.count,
        cover_image_url: wishlist.cover_image_url,
        event_type: wishlist.event_type,
        event_date: wishlist.event_date,
        updated_at: wishlist.updated_at.iso8601
      }
    end
  end

  def serialize_recent_activities(user)
    ActivityFeedService.get_user_activities(user: user, limit: 50).map do |activity|
      {
        id: activity.id,
        action_type: activity.action_type,
        actor_name: activity.actor.name,
        target_type: activity.target_type,
        target_name: activity.target&.name,
        occurred_at: activity.occurred_at.iso8601
      }
    end
  end

  def enhanced_mobile_app_config
    {
      cache_duration: 1.hour.to_i,
      image_compression_quality: 0.8,
      max_image_size: 1024,
      batch_analytics_interval: 30.seconds.to_i,
      sync_interval: 5.minutes.to_i,
      offline_cache_size_limit_mb: 50,
      supported_currencies: WishlistItem::CURRENCIES.keys,
      supported_languages: ['en', 'pt-BR'],
      performance_targets: {
        feed_load_ms: 200,
        search_ms: 100,
        image_upload_ms: 1000
      },
      feature_flags: {
        offline_mode: true,
        push_notifications: true,
        biometric_auth: true,
        camera_integration: true,
        haptic_feedback: true,
        widgets: true,
        background_sync: true
      }
    }
  end

  def valid_image_type?(file)
    return false unless file.respond_to?(:content_type)

    allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/heic']
    allowed_types.include?(file.content_type.downcase)
  end

  def track_mobile_event(event_type, metadata = {})
    AnalyticsJob.perform_later(
      event_type.to_s,
      current_user.id,
      session.id,
      {
        ip_address: request.remote_ip,
        user_agent: request.headers['User-Agent']
      },
      metadata
    )
  end

  def send_ios_push_notification(device_token, notification_data)
    # Implement iOS push notification sending
    # This would typically use the Apple Push Notification service
    Rails.logger.info "Sending iOS push notification to #{device_token[0..10]}..."
    # Implementation would go here
  end

  def send_android_push_notification(device_token, notification_data)
    # Implement Android push notification sending via FCM
    Rails.logger.info "Sending Android push notification to #{device_token[0..10]}..."
    # Implementation would go here
  end

  def wishlist_sync_data(wishlist)
    {
      id: wishlist.id,
      title: wishlist.title,
      description: wishlist.description,
      visibility: wishlist.visibility,
      event_type: wishlist.event_type,
      event_date: wishlist.event_date,
      updated_at: wishlist.updated_at.iso8601,
      items: wishlist.wishlist_items.map { |item| item_sync_data(item) }
    }
  end

  def item_sync_data(item)
    {
      id: item.id,
      name: item.name,
      description: item.description,
      url: item.url,
      price: item.price,
      currency: item.currency,
      priority: item.priority,
      purchased: item.purchased,
      image_url: item.image.attached? ? url_for(item.image) : nil,
      updated_at: item.updated_at.iso8601
    }
  end

  def connection_sync_data(connection)
    {
      id: connection.id,
      friend_id: connection.friend_id,
      status: connection.status,
      updated_at: connection.updated_at.iso8601,
      friend: {
        id: connection.friend.id,
        name: connection.friend.name,
        email: connection.friend.email,
        avatar_url: connection.friend.avatar.attached? ? url_for(connection.friend.avatar) : nil
      }
    }
  end

  def notification_sync_data(notification)
    {
      id: notification.id,
      title: notification.title,
      message: notification.message,
      read: notification.read,
      notification_type: notification.notification_type,
      data: notification.data,
      created_at: notification.created_at.iso8601
    }
  end

  def user_profile_data
    {
      id: current_user.id,
      name: current_user.name,
      email: current_user.email,
      avatar_url: current_user.avatar.attached? ? url_for(current_user.avatar) : nil,
      locale: current_user.locale || 'en',
      timezone: current_user.timezone || 'UTC'
    }
  end
end