require "net/http"
require "uri"
require "json"

class PushNotificationService
  FCM_URL = "https://fcm.googleapis.com/fcm/send"

  def initialize
    @server_key = Rails.application.credentials.fcm_server_key rescue nil
  end

  def send_notification(user:, title:, body:, data: {})
    return unless @server_key.present?
    return unless user.notification_preference&.push_enabled?

    active_tokens = user.device_tokens.active
    return if active_tokens.empty?

    active_tokens.each do |device_token|
      send_to_token(
        token: device_token.token,
        title: title,
        body: body,
        data: data,
        platform: device_token.platform
      )
    end
  end

  def send_item_purchase_notification(notification)
    user = notification.user
    data = notification.data

    I18n.with_locale(user.preferred_locale || I18n.default_locale) do
      title = I18n.t("notifications.types.item_purchased.title")
      body = I18n.t("notifications.types.item_purchased.message",
                    purchaser_name: data["purchaser_name"] || "Someone",
                    item_name: data["item_name"] || "an item")

      send_notification(
        user: user,
        title: title,
        body: body,
        data: {
          notification_type: "item_purchased",
          notification_id: notification.id,
          wishlist_id: data["wishlist_id"],
          item_id: data["item_id"]
        }
      )
    end
  end

  def send_invitation_notification(notification)
    user = notification.user
    data = notification.data

    I18n.with_locale(user.preferred_locale || I18n.default_locale) do
      case notification.notification_type
      when "invitation_received"
        title = I18n.t("notifications.types.invitation_received.title")
        body = I18n.t("notifications.types.invitation_received.message",
                      sender_name: data["sender_name"] || "Someone")
      when "invitation_accepted"
        title = I18n.t("notifications.types.invitation_accepted.title")
        body = I18n.t("notifications.types.invitation_accepted.message",
                      acceptor_name: data["acceptor_name"] || "Someone")
      when "invitation_declined"
        title = I18n.t("notifications.types.invitation_declined.title")
        body = I18n.t("notifications.types.invitation_declined.message")
      end

      send_notification(
        user: user,
        title: title,
        body: body,
        data: {
          notification_type: notification.notification_type,
          notification_id: notification.id,
          invitation_token: data["invitation_token"]
        }
      )
    end
  end

  private

  def send_to_token(token:, title:, body:, data:, platform:)
    payload = build_payload(
      token: token,
      title: title,
      body: body,
      data: data,
      platform: platform
    )

    uri = URI.parse(FCM_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "key=#{@server_key}"
    request.body = payload.to_json

    response = http.request(request)

    handle_response(response, token)
  end

  def build_payload(token:, title:, body:, data:, platform:)
    payload = {
      to: token,
      data: data
    }

    case platform.to_s
    when "ios"
      payload[:notification] = {
        title: title,
        body: body,
        sound: "default",
        badge: 1
      }
      payload[:priority] = "high"
      payload[:content_available] = true
    when "android"
      payload[:notification] = {
        title: title,
        body: body,
        sound: "default",
        icon: "ic_notification",
        color: "#EC4899"
      }
      payload[:priority] = "high"
    when "web"
      payload[:notification] = {
        title: title,
        body: body,
        icon: "/icon-192x192.png",
        click_action: Rails.application.routes.url_helpers.notifications_url
      }
    end

    payload
  end

  def handle_response(response, token)
    case response.code.to_i
    when 200
      result = JSON.parse(response.body)

      if result["failure"] > 0
        Rails.logger.warn "FCM push notification failed for token #{token}: #{result}"
        # TODO: Handle invalid tokens by marking them as inactive
      else
        Rails.logger.info "FCM push notification sent successfully to token #{token}"
      end
    else
      Rails.logger.error "FCM request failed with status #{response.code}: #{response.body}"
    end
  end
end
