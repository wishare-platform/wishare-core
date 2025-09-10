class CreateDeviceTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :device_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.integer :platform, null: false
      t.boolean :active, default: true, null: false
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :device_tokens, [:user_id, :token], unique: true
    add_index :device_tokens, [:user_id, :platform]
    add_index :device_tokens, :active
    add_index :device_tokens, :last_used_at
  end
end
