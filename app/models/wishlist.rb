class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_items, dependent: :destroy

  enum :visibility, { private_list: 0, partner_only: 1 }

  validates :name, presence: true
  validates :visibility, presence: true

  scope :default_lists, -> { where(is_default: true) }
  scope :custom_lists, -> { where(is_default: false) }
end
