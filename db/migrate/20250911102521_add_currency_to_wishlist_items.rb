class AddCurrencyToWishlistItems < ActiveRecord::Migration[8.0]
  def change
    add_column :wishlist_items, :currency, :string, limit: 3, default: 'USD'
    add_index :wishlist_items, :currency
  end
end
