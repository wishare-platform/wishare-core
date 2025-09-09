class AddEventFieldsToWishlists < ActiveRecord::Migration[8.0]
  def change
    add_column :wishlists, :event_date, :date
    add_column :wishlists, :event_type, :string
  end
end
