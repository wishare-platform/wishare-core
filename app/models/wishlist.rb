class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_items, 
  has_many :items, through: :wishlist_items

  validates :name, presence: true
end
