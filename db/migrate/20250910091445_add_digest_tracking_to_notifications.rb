class AddDigestTrackingToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :digest_processed_at, :datetime
    add_column :notifications, :digest_frequency_sent, :string
  end
end
