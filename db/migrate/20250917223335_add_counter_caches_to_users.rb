class AddCounterCachesToUsers < ActiveRecord::Migration[8.0]
  def change
    # Counter caches for frequently accessed counts
    add_column :users, :wishlists_count, :integer, default: 0, null: false
    add_column :users, :connections_count, :integer, default: 0, null: false
    add_column :users, :activity_feeds_count, :integer, default: 0, null: false

    # Add indexes for counter cache columns
    add_index :users, :wishlists_count
    add_index :users, :connections_count
    add_index :users, :activity_feeds_count

    # Initialize counter caches with current counts
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET
            wishlists_count = (SELECT COUNT(*) FROM wishlists WHERE wishlists.user_id = users.id),
            connections_count = (SELECT COUNT(*) FROM connections WHERE connections.user_id = users.id AND connections.status = 1),
            activity_feeds_count = (SELECT COUNT(*) FROM activity_feeds WHERE activity_feeds.user_id = users.id)
        SQL
      end
    end
  end
end
