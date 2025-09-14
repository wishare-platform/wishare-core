class Api::V1::MobileController < Api::V1::BaseController
  before_action :authenticate_user!, except: [:health_check]

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

  private

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