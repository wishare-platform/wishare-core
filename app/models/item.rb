class Item < ApplicationRecord
  has_many :wishlist_items
  has_many :wishlists, through: :wishlist_items

  validates :name, presence: true
  validates :link, presence: true
end
