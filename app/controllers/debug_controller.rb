class DebugController < ApplicationController
  # Only allow in development or for admin users
  before_action :ensure_debug_access

  def analytics_status
    @consent_record = CookieConsent.find_consent_for_request(request, current_user)
    @has_analytics_consent = @consent_record&.analytics_enabled? == true
    @session_id = CookieConsent.extract_session_id(request)
    @gtm_id = "GTM-53FTHDK7"

    respond_to do |format|
      format.html
      format.json do
        render json: {
          has_consent: @has_analytics_consent,
          consent_record: @consent_record&.attributes,
          session_id: @session_id,
          gtm_id: @gtm_id,
          user_signed_in: user_signed_in?,
          current_user_id: current_user&.id
        }
      end
    end
  end

  def toggle_consent
    consent = CookieConsent.find_or_create_for_request(request, current_user)
    consent.update!(analytics_enabled: !consent.analytics_enabled)

    redirect_to debug_analytics_status_path, notice: "Analytics consent #{consent.analytics_enabled? ? 'enabled' : 'disabled'}"
  end

  private

  def ensure_debug_access
    unless Rails.env.development? || (current_user&.email&.include?("@"))
      redirect_to root_path, alert: "Access denied"
    end
  end
end
