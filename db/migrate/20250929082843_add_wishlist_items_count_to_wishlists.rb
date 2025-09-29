class AddWishlistItemsCountToWishlists < ActiveRecord::Migration[8.0]
  def change
    add_column :wishlists, :wishlist_items_count, :integer, default: 0, null: false

    # Populate existing counter cache values
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE wishlists
          SET wishlist_items_count = (
            SELECT COUNT(*)
            FROM wishlist_items
            WHERE wishlist_items.wishlist_id = wishlists.id
          )
        SQL
      end
    end
  end
end
