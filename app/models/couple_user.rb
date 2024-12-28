class CoupleUser < ApplicationRecord
  belongs_to :couple
  belongs_to :user
end
