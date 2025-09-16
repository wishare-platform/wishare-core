class CreateShareAnalytics < ActiveRecord::Migration[8.0]
  def change
    create_table :share_analytics do |t|
      t.references :user, null: false, foreign_key: true
      t.string :shareable_type, null: false
      t.bigint :shareable_id, null: false
      t.string :platform, null: false
      t.datetime :shared_at, null: false
      t.integer :clicks, default: 0

      t.timestamps
    end

    add_index :share_analytics, [:shareable_type, :shareable_id]
    add_index :share_analytics, :platform
    add_index :share_analytics, :shared_at
    add_index :share_analytics, [:user_id, :platform]
  end
end
