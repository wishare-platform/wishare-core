class CreateWishlists < ActiveRecord::Migration[8.0]
  def change
    create_table :wishlists do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.boolean :is_default
      t.integer :visibility

      t.timestamps
    end
  end
end
