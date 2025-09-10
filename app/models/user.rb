class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [:google_oauth2]

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

  validates :name, presence: true
  validates :preferred_locale, inclusion: { in: %w[en pt-BR] }

  after_create :create_default_notification_preference

  def self.from_omniauth(auth)
    user = find_or_create_by(provider: auth.provider, uid: auth.uid) do |u|
      u.email = auth.info.email
      u.password = Devise.friendly_token[0, 20]
      u.name = auth.info.name
      u.avatar_url = auth.info.image
      
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
    
    # Update avatar_url, name and potentially birthday for existing users
    update_fields = {}
    update_fields[:avatar_url] = auth.info.image if user.avatar_url != auth.info.image
    update_fields[:name] = auth.info.name if user.name != auth.info.name
    
    # Try to update birthday if we don't have one yet
    if user.date_of_birth.nil? && auth.extra && auth.extra.raw_info && auth.extra.raw_info.birthday
      begin
        update_fields[:date_of_birth] = Date.parse(auth.extra.raw_info.birthday)
      rescue Date::Error
        # Ignore if birthday format is invalid
      end
    end
    
    user.update(update_fields) if user.persisted? && update_fields.any?
    
    user
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

  private

  def create_default_notification_preference
    build_notification_preference.save unless notification_preference
  end
end
