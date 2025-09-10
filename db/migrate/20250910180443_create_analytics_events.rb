class CreateAnalyticsEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_events do |t|
      t.references :user, null: true, foreign_key: true # Allow anonymous events
      t.integer :event_type, null: false
      t.json :metadata # Use JSON column for better performance
      t.string :session_id
      t.inet :ip_address # Use inet for IP addresses
      t.text :user_agent
      t.string :page_path
      t.string :page_title
      t.string :referrer

      t.timestamps
    end
    
    add_index :analytics_events, :event_type
    add_index :analytics_events, :created_at
    add_index :analytics_events, [:user_id, :event_type]
    add_index :analytics_events, :session_id
  end
end
