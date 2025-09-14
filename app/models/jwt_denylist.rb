class JwtDenylist < ApplicationRecord
  self.table_name = 'jwt_denylists'

  belongs_to :user, optional: true

  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  # Clean up expired tokens
  scope :expired, -> { where('exp < ?', Time.current) }

  def self.cleanup_expired!
    expired.delete_all
  end

  def expired?
    exp < Time.current
  end
end
