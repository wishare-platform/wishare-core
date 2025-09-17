class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2]

  # Include mobile support functionality
  include UserMobileSupport

  # ActiveStorage attachments
  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
    attachable.variant :large, resize_to_limit: [300, 300]
  end

  has_one_attached :cover_image do |attachable|
    attachable.variant :large, resize_to_limit: [1200, 400]
    attachable.variant :thumb, resize_to_limit: [600, 200]
  end

  # Connection associations
  has_many :connections, dependent: :destroy
  has_many :inverse_connections, class_name: 'Connection', foreign_key: 'partner_id', dependent: :destroy
  has_many :partners, through: :connections, source: :partner
  has_many :inverse_partners, through: :inverse_connections, source: :user

  # Invitation associations
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_invitations, class_name: 'Invitation', foreign_key: 'recipient_email', primary_key: 'email', dependent: :destroy

  # Wishlist associations
  has_many :wishlists, dependent: :destroy
  has_many :purchased_items, class_name: 'WishlistItem', foreign_key: 'purchased_by_id', dependent: :nullify

  # Notification associations
  has_many :notifications, dependent: :destroy
  has_one :notification_preference, dependent: :destroy
  has_many :device_tokens, dependent: :destroy

  # Analytics associations
  has_one :user_analytic, dependent: :destroy
  has_many :share_analytics, dependent: :destroy
  has_many :shares_as_shareable, class_name: 'ShareAnalytic', as: :shareable, dependent: :destroy

  validates :name, presence: true
  validates :preferred_locale, inclusion: { in: %w[en pt-BR] }
  validates :theme_preference, inclusion: { in: %w[light dark system] }

  # Strong password validation
  validate :password_complexity, if: :password_required?
  
  # Address field validations - all required except apartment_unit
  validate :address_completeness

  # Social field validations
  validates :bio, length: { maximum: 500 }
  validates :website, format: { with: URI::regexp(%w[http https]), allow_blank: true }
  validates :instagram_username, format: { with: /\A[a-zA-Z0-9_.]+\z/, allow_blank: true }
  validates :tiktok_username, format: { with: /\A[a-zA-Z0-9_.]+\z/, allow_blank: true }
  validates :twitter_username, format: { with: /\A[a-zA-Z0-9_]+\z/, allow_blank: true }
  validates :linkedin_url, format: { with: URI::regexp(%w[http https]), allow_blank: true }
  validates :youtube_url, format: { with: URI::regexp(%w[http https]), allow_blank: true }
  validates :facebook_url, format: { with: URI::regexp(%w[http https]), allow_blank: true }

  # Role-based access control
  enum :role, {
    user: 0,
    admin: 1,
    super_admin: 2
  }, default: :user

  # Gender enum
  enum :gender, {
    not_specified: 0,
    male: 1,
    female: 2,
    non_binary: 3,
    prefer_not_to_say: 4
  }, default: :not_specified, prefix: true

  # Address visibility control
  enum :address_visibility, {
    private: 0,           # Only visible to user
    connected_users: 1,   # Visible to friends & family
    public: 2            # Visible on public profile
  }, default: :private, prefix: true

  # Bio visibility control
  enum :bio_visibility, {
    private: 0,           # Only visible to user
    connected_users: 1,   # Visible to friends & family
    public: 2            # Visible on public profile
  }, default: :public, prefix: true

  # Social links visibility control
  enum :social_links_visibility, {
    private: 0,           # Only visible to user
    connected_users: 1,   # Visible to friends & family
    public: 2            # Visible on public profile
  }, default: :public, prefix: true

  # Website visibility control
  enum :website_visibility, {
    private: 0,           # Only visible to user
    connected_users: 1,   # Visible to friends & family
    public: 2            # Visible on public profile
  }, default: :public, prefix: true

  after_create :create_default_notification_preference

  def self.from_omniauth(auth)
    # First, try to find by provider and uid (existing OAuth user)
    user = find_by(provider: auth.provider, uid: auth.uid)
    
    # If not found, try to find by email (could be an existing email/password user)
    if user.nil?
      user = find_by(email: auth.info.email)
      
      if user
        # User exists with this email, link the OAuth account
        user.update(
          provider: auth.provider,
          uid: auth.uid,
          avatar_url: auth.info.image || user.avatar_url,
          name: user.name.presence || auth.info.name
        )
      else
        # Create new user
        user = create! do |u|
          u.email = auth.info.email
          u.password = Devise.friendly_token[0, 20]
          u.name = auth.info.name
          u.avatar_url = auth.info.image
          u.provider = auth.provider
          u.uid = auth.uid
          
          # Try to extract birthday from Google+ extra_info or raw_info
          # Note: Google has restricted birthday access, but we can try
          if auth.extra && auth.extra.raw_info && auth.extra.raw_info.birthday
            begin
              u.date_of_birth = Date.parse(auth.extra.raw_info.birthday)
            rescue Date::Error
              # Ignore if birthday format is invalid
            end
          end
        end
      end
    else
      # Existing OAuth user - update their info
      update_fields = {}
      update_fields[:avatar_url] = auth.info.image if auth.info.image && user.avatar_url != auth.info.image
      update_fields[:name] = auth.info.name if auth.info.name && user.name != auth.info.name
      
      # Try to update birthday if we don't have one yet
      if user.date_of_birth.nil? && auth.extra && auth.extra.raw_info && auth.extra.raw_info.birthday
        begin
          update_fields[:date_of_birth] = Date.parse(auth.extra.raw_info.birthday)
        rescue Date::Error
          # Ignore if birthday format is invalid
        end
      end
      
      user.update(update_fields) if update_fields.any?
    end
    
    user
  end

  def has_password?
    encrypted_password.present?
  end

  def oauth_only?
    provider.present? && !has_password?
  end

  def all_connections
    Connection.where("user_id = ? OR partner_id = ?", id, id)
  end

  def accepted_connections
    all_connections.accepted_connections
  end

  def partner
    accepted_connection = accepted_connections.first
    return nil unless accepted_connection
    
    accepted_connection.other_user(self)
  end

  def connected_to?(other_user)
    return false if other_user.nil?

    Connection.between_users(self, other_user)&.accepted?
  end

  def profile_avatar_url(variant: :thumb)
    if avatar.attached?
      if avatar.variable?
        Rails.application.routes.url_helpers.rails_representation_url(
          avatar.variant(variant),
          host: Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
        )
      else
        Rails.application.routes.url_helpers.rails_blob_url(
          avatar,
          host: Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
        )
      end
    else
      # Fallback to OAuth avatar stored in avatar_url field
      read_attribute(:avatar_url)
    end
  rescue
    read_attribute(:avatar_url)
  end

  def connection_with(other_user)
    return nil if other_user.nil?
    
    Connection.between_users(self, other_user)
  end

  def pending_invitation_to?(email)
    sent_invitations.pending_invitations.exists?(recipient_email: email)
  end

  def display_name
    name.presence || email.split('@').first
  end

  def unread_notifications_count
    notifications.unread.count
  end

  def has_address?
    street_address.present? || city.present? || postal_code.present? || street_number.present?
  end

  def full_address
    return nil unless has_address?
    
    parts = []
    
    # Build street line: number + street + apartment
    street_line = []
    street_line << street_number if street_number.present?
    street_line << street_address if street_address.present?
    street_parts = street_line.join(' ')
    street_parts += " #{apartment_unit}" if apartment_unit.present?
    parts << street_parts if street_parts.present?
    
    # City, state line
    parts << "#{city}, #{state}" if city.present? && state.present?
    parts << city if city.present? && state.blank?
    
    # Postal code
    parts << "#{postal_code}" if postal_code.present?
    
    # Country
    parts << country_name if country.present?
    
    parts.join(', ')
  end

  def country_name
    return nil unless country.present?
    
    # ISO country code to name mapping for most common countries
    country_mapping = {
      'US' => 'United States',
      'BR' => 'Brazil',
      'CA' => 'Canada',
      'GB' => 'United Kingdom',
      'AU' => 'Australia',
      'DE' => 'Germany',
      'FR' => 'France',
      'ES' => 'Spain',
      'IT' => 'Italy',
      'MX' => 'Mexico',
      'AR' => 'Argentina'
    }
    
    country_mapping[country] || country
  end

  def can_view_address?(viewer)
    return false unless has_address?
    return true if viewer == self

    case address_visibility.to_sym
    when :address_private
      false
    when :connected_users
      viewer && connected_to?(viewer)
    when :address_public
      true
    else
      false
    end
  end

  # Social media methods
  def social_links
    {
      instagram: formatted_social_url(:instagram),
      tiktok: formatted_social_url(:tiktok),
      twitter: formatted_social_url(:twitter),
      linkedin: linkedin_url,
      youtube: youtube_url,
      facebook: facebook_url,
      website: website
    }.compact
  end

  def formatted_social_url(platform)
    case platform
    when :instagram
      return nil if instagram_username.blank?
      "https://instagram.com/#{instagram_username}"
    when :tiktok
      return nil if tiktok_username.blank?
      "https://tiktok.com/@#{tiktok_username}"
    when :twitter
      return nil if twitter_username.blank?
      "https://twitter.com/#{twitter_username}"
    end
  end

  def has_social_presence?
    social_links.any? { |_, url| url.present? }
  end

  def has_social_links?
    has_social_presence?
  end

  def can_view_bio?(viewer)
    return true if viewer == self

    case bio_visibility.to_sym
    when :bio_visibility_private
      false
    when :bio_visibility_connected_users
      viewer && connected_to?(viewer)
    when :bio_visibility_public
      true
    else
      false
    end
  end

  def can_view_social_links?(viewer)
    return true if viewer == self

    case social_links_visibility.to_sym
    when :social_links_visibility_private
      false
    when :social_links_visibility_connected_users
      viewer && connected_to?(viewer)
    when :social_links_visibility_public
      true
    else
      false
    end
  end

  def can_view_website?(viewer)
    return true if viewer == self

    case website_visibility.to_sym
    when :website_visibility_private
      false
    when :website_visibility_connected_users
      viewer && connected_to?(viewer)
    when :website_visibility_public
      true
    else
      false
    end
  end

  private
  
  def address_completeness
    # If user is providing any address information, require all fields except apartment_unit
    if address_fields_present?
      validation_messages = {
        street_number: I18n.t('profile.edit.address.validation.street_number_required'),
        street_address: I18n.t('profile.edit.address.validation.street_address_required'),
        city: I18n.t('profile.edit.address.validation.city_required'),
        state: I18n.t('profile.edit.address.validation.state_required'),
        postal_code: I18n.t('profile.edit.address.validation.postal_code_required'),
        country: I18n.t('profile.edit.address.validation.country_required')
      }

      validation_messages.each do |field, message|
        if send(field).blank?
          errors.add(field, message)
        end
      end
    end
  end
  
  def address_fields_present?
    [street_number, street_address, city, state, postal_code, country, apartment_unit].any?(&:present?)
  end

  def create_default_notification_preference
    build_notification_preference.save unless notification_preference
  end

  def password_complexity
    return if password.blank?

    errors.add(:password, 'must be at least 12 characters long') if password.length < 12
    errors.add(:password, 'must include at least one uppercase letter') unless password =~ /[A-Z]/
    errors.add(:password, 'must include at least one lowercase letter') unless password =~ /[a-z]/
    errors.add(:password, 'must include at least one number') unless password =~ /\d/
    errors.add(:password, 'must include at least one special character') unless password =~ /[^A-Za-z0-9]/
  end

  def password_required?
    !persisted? || !password.blank?
  end
end
