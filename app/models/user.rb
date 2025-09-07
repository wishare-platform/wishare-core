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

  # Wishlist associations
  has_many :wishlists, dependent: :destroy
  has_many :purchased_items, class_name: 'WishlistItem', foreign_key: 'purchased_by_id', dependent: :nullify

  validates :name, presence: true

  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image
    end
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

  def pending_invitation_to?(email)
    sent_invitations.pending_invitations.exists?(recipient_email: email)
  end

  def display_name
    name.presence || email.split('@').first
  end
end
