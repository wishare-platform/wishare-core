class Invitation < ApplicationRecord
  belongs_to :sender, class_name: 'User'

  enum :status, { pending: 0, accepted: 1, expired: 2 }

  validates :recipient_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validate :cannot_invite_self, on: :create
  validate :no_duplicate_pending_invitations, on: :create
  validate :cannot_invite_existing_partner, on: :create

  before_validation :generate_token, on: :create

  scope :pending_invitations, -> { where(status: :pending) }
  scope :not_expired, -> { where('created_at > ?', 7.days.ago) }

  def expired?
    return false if created_at.nil?
    created_at < 7.days.ago
  end

  def mark_as_expired!
    update_columns(status: :expired, updated_at: Time.current)
  end

  def accept!(recipient_user)
    transaction do
      # Check if connection already exists
      existing_connection = Connection.between_users(sender, recipient_user)
      
      if existing_connection
        # Update existing connection to accepted
        existing_connection.update!(status: :accepted)
      else
        # Create new connection
        Connection.create!(
          user: sender,
          partner: recipient_user,
          status: :accepted
        )
      end
      
      # Mark invitation as accepted
      update_columns(
        status: :accepted,
        accepted_at: Time.current,
        updated_at: Time.current
      )
    end
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def cannot_invite_self
    errors.add(:recipient_email, "can't invite yourself") if sender&.email == recipient_email
  end

  def no_duplicate_pending_invitations
    if sender&.sent_invitations&.pending_invitations&.exists?(recipient_email: recipient_email)
      errors.add(:recipient_email, "already has a pending invitation")
    end
  end

  def cannot_invite_existing_partner
    return unless sender && recipient_email
    
    recipient = User.find_by(email: recipient_email)
    if recipient && sender.connected_to?(recipient)
      errors.add(:recipient_email, "is already your partner")
    end
  end
end
