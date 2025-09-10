class CreateUserAnalytics < ActiveRecord::Migration[8.0]
  def change
    create_table :user_analytics do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :wishlists_created_count, default: 0
      t.integer :items_added_count, default: 0
      t.integer :connections_count, default: 0
      t.integer :invitations_sent_count, default: 0
      t.integer :invitations_accepted_count, default: 0
      t.integer :items_purchased_count, default: 0
      t.integer :page_views_count, default: 0
      t.datetime :last_activity_at
      t.datetime :first_activity_at

      t.timestamps
    end
    
    add_index :user_analytics, :user_id, unique: true, name: 'index_user_analytics_on_user_id_unique'
    add_index :user_analytics, :last_activity_at
  end
end
