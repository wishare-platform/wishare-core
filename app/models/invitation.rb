class Invitation < ApplicationRecord
  belongs_to :sender, class_name: 'User'

  enum :status, { pending: 0, accepted: 1, expired: 2 }

  validates :recipient_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validate :cannot_invite_self

  before_validation :generate_token, on: :create
  before_validation :set_expiry_time, on: :create

  scope :pending_invitations, -> { where(status: :pending) }
  scope :not_expired, -> { where('created_at > ?', 7.days.ago) }

  def expired?
    created_at < 7.days.ago
  end

  def mark_as_expired!
    update!(status: :expired)
  end

  def accept!(recipient_user)
    transaction do
      # Create the connection
      Connection.create!(
        user: sender,
        partner: recipient_user,
        status: :accepted
      )
      
      # Mark invitation as accepted
      update!(
        status: :accepted,
        accepted_at: Time.current
      )
    end
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end

  def set_expiry_time
    # Auto-expire invitations after 7 days
    mark_as_expired! if expired?
  end

  def cannot_invite_self
    errors.add(:recipient_email, "can't invite yourself") if sender&.email == recipient_email
  end
end
