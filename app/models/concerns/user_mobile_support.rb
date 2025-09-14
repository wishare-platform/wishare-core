# frozen_string_literal: true

module UserMobileSupport
  extend ActiveSupport::Concern

  included do
    # Device info is stored as JSONB in the database (natively supported by PostgreSQL)
    has_many :device_tokens, dependent: :destroy

    # No need to serialize device_info - it's already a jsonb column
  end

  # Update device information for mobile apps
  def update_device_info(device_data)
    current_info = device_info || {}

    updated_info = current_info.merge(
      platform: device_data[:platform],
      device_type: device_data[:device_type],
      app_version: device_data[:app_version],
      os_version: device_data[:os_version],
      device_model: device_data[:device_model],
      screen_size: device_data[:screen_size],
      language: device_data[:language],
      timezone: device_data[:timezone],
      last_updated: Time.current.iso8601
    )

    update!(device_info: updated_info)
  end

  # Check if user has mobile app installed
  def has_mobile_app?
    device_tokens.exists?
  end

  # Get user's preferred platform
  def preferred_mobile_platform
    return nil unless device_info.present?
    device_info['platform']
  end

  # Get latest app version for user
  def mobile_app_version
    return nil unless device_info.present?
    device_info['app_version']
  end

  # Check if user needs app update
  def needs_app_update?(minimum_version)
    return false unless mobile_app_version

    # Simple version comparison (assumes semantic versioning)
    current_version = mobile_app_version.split('.').map(&:to_i)
    min_version = minimum_version.split('.').map(&:to_i)

    current_version < min_version
  end

  # Get device capabilities
  def device_capabilities
    return {} unless device_info.present?

    {
      biometric_available: device_supports_biometric?,
      camera_available: device_supports_camera?,
      push_notifications: device_supports_push?,
      screen_size: device_info['screen_size'],
      platform: device_info['platform']
    }
  end

  # Check device-specific capabilities
  def device_supports_biometric?
    return false unless device_info.present?

    case device_info['platform']
    when 'ios'
      # iOS devices generally support Touch ID or Face ID
      true
    when 'android'
      # Most modern Android devices support fingerprint
      device_info['os_version'].to_f >= 6.0 if device_info['os_version']
    else
      false
    end
  end

  def device_supports_camera?
    # Most mobile devices have cameras
    has_mobile_app?
  end

  def device_supports_push?
    # If they have device tokens, they support push
    device_tokens.exists?
  end

  # Mobile analytics helpers
  def mobile_usage_stats
    {
      total_sessions: mobile_sessions_count,
      last_active: last_mobile_activity,
      preferred_platform: preferred_mobile_platform,
      app_version: mobile_app_version,
      notifications_enabled: device_tokens.count > 0
    }
  end

  private

  def mobile_sessions_count
    # This would require session tracking - placeholder for now
    0
  end

  def last_mobile_activity
    device_tokens.maximum(:updated_at) || updated_at
  end
end