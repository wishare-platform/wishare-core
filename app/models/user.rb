class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2]

  # Include mobile support functionality
  include UserMobileSupport

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

  # Analytics association
  has_one :user_analytic, dependent: :destroy

  validates :name, presence: true
  validates :preferred_locale, inclusion: { in: %w[en pt-BR] }
  validates :theme_preference, inclusion: { in: %w[light dark system] }

  # Strong password validation
  validate :password_complexity, if: :password_required?
  
  # Address field validations - all required except apartment_unit
  validate :address_completeness
  
  # Role-based access control
  enum :role, {
    user: 0,
    admin: 1,
    super_admin: 2
  }, default: :user

  # Address visibility control
  enum :address_visibility, {
    private: 0,           # Only visible to user
    connected_users: 1,   # Visible to friends & family
    public: 2            # Visible on public profile
  }, default: :private, prefix: true

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
        user = create do |u|
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

  private
  
  def address_completeness
    # If user is providing any address information, require all fields except apartment_unit
    if address_fields_present?
      required_address_fields = [:street_number, :street_address, :city, :state, :postal_code, :country]
      
      required_address_fields.each do |field|
        if send(field).blank?
          errors.add(field, :blank)
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
