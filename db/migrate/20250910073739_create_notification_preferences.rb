class CreateNotificationPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :email_invitations, default: true, null: false
      t.boolean :email_purchases, default: true, null: false
      t.boolean :email_new_items, default: false, null: false
      t.boolean :email_connections, default: true, null: false
      t.boolean :push_enabled, default: false, null: false
      t.integer :digest_frequency, default: 0

      t.timestamps
    end
  end
end
