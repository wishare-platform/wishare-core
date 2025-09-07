class CreateWishlistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :wishlist_items do |t|
      t.references :wishlist, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :price
      t.string :url
      t.string :image_url
      t.integer :priority
      t.integer :status
      t.references :purchased_by, null: true, foreign_key: { to_table: :users }
      t.datetime :purchased_at

      t.timestamps
    end
  end
end
