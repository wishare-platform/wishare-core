class AddAddressFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :street_address, :text
    add_column :users, :city, :string
    add_column :users, :state, :string
    add_column :users, :postal_code, :string
    add_column :users, :country, :string, limit: 2 # ISO country code
    add_column :users, :address_visibility, :integer, default: 0, null: false
    
    add_index :users, :postal_code
    add_index :users, :country
    add_index :users, :address_visibility
  end
end
