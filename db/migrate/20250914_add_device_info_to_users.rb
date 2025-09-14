class AddDeviceInfoToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :device_info, :jsonb, default: {}
    add_index :users, :device_info, using: :gin
  end
end