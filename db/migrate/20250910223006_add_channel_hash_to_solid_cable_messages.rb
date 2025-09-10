class AddChannelHashToSolidCableMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :solid_cable_messages, :channel_hash, :string
    add_index :solid_cable_messages, :channel_hash
  end
end
