class CreateActivityFeeds < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_feeds do |t|
      t.references :user, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action_type, null: false
      t.references :target, polymorphic: true, null: false
      t.json :metadata
      t.boolean :is_public, default: true
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :activity_feeds, [:user_id, :occurred_at]
    add_index :activity_feeds, [:actor_id, :occurred_at]
    add_index :activity_feeds, [:action_type, :occurred_at]
    add_index :activity_feeds, [:target_type, :target_id]
    add_index :activity_feeds, [:is_public, :occurred_at]
  end
end
