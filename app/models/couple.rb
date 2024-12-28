class Couple < ApplicationRecord
  has_many :couple_users
  has_many :users, through: :couple_users

  def partner_of(user)
    users.where.not(id: user.id).first
  end
end
