class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.integer :notification_type
      t.string :title
      t.text :message
      t.boolean :read, default: false, null: false
      t.json :data

      t.timestamps
    end
    
    add_index :notifications, [:user_id, :read]
    add_index :notifications, :created_at
  end
end
