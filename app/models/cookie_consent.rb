require "digest"
require "securerandom"

class CookieConsent < ApplicationRecord
  belongs_to :user, optional: true

  # Validations
  validates :consent_date, presence: true
  validates :session_id, presence: true, unless: :user_id?
  validates :consent_version, presence: true

  # Scopes
  scope :recent, -> { order(consent_date: :desc) }
  scope :analytics_enabled, -> { where(analytics_enabled: true) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_session, ->(session_id) { where(session_id: session_id) }
  scope :current_version, -> { where(consent_version: CURRENT_VERSION) }

  # Constants
  CURRENT_VERSION = "1.0".freeze

  # Class methods
  def self.find_or_create_for_request(request, user = nil)
    session_id = extract_session_id(request)

    consent = if user
      find_by(user: user) || find_by(session_id: session_id)
    else
      find_by(session_id: session_id)
    end

    return consent if consent&.current_version?

    # Create new consent record
    create!(
      user: user,
      session_id: session_id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      consent_date: Time.current,
      consent_version: CURRENT_VERSION,
      # Default to false - user must explicitly consent
      analytics_enabled: false,
      marketing_enabled: false,
      functional_enabled: true
    )
  end

  def self.has_analytics_consent?(request, user = nil)
    consent = find_consent_for_request(request, user)
    consent&.analytics_enabled? || false
  end

  def self.find_consent_for_request(request, user = nil)
    session_id = extract_session_id(request)

    if user
      find_by(user: user) || find_by(session_id: session_id)
    else
      find_by(session_id: session_id)
    end
  end

  def self.extract_session_id(request)
    # Try different ways to get session ID
    if request.session.respond_to?(:id)
      request.session.id.to_s
    elsif request.session.respond_to?(:session_id)
      request.session.session_id.to_s
    else
      # Fallback to a hash of the session data
      Digest::SHA256.hexdigest(request.session.to_hash.to_s)[0..32]
    end
  rescue => e
    Rails.logger.warn "Failed to extract session ID: #{e.message}"
    # Generate a random session ID as fallback
    SecureRandom.hex(16)
  end

  # Instance methods
  def current_version?
    consent_version == CURRENT_VERSION
  end

  def anonymous?
    user_id.nil?
  end

  def update_consent!(analytics: nil, marketing: nil, functional: nil, request: nil)
    updates = {}
    updates[:analytics_enabled] = analytics unless analytics.nil?
    updates[:marketing_enabled] = marketing unless marketing.nil?
    updates[:functional_enabled] = functional unless functional.nil?
    updates[:consent_date] = Time.current

    if request
      updates[:ip_address] = request.remote_ip
      updates[:user_agent] = request.user_agent
    end

    update!(updates)
  end

  def consent_summary
    {
      analytics: analytics_enabled?,
      marketing: marketing_enabled?,
      functional: functional_enabled?,
      date: consent_date,
      version: consent_version
    }
  end
end
