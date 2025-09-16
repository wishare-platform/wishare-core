class AddSocialFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :bio, :text
    add_column :users, :website, :string
    add_column :users, :gender, :integer, default: 0
    add_column :users, :instagram_username, :string
    add_column :users, :tiktok_username, :string
    add_column :users, :twitter_username, :string
    add_column :users, :linkedin_url, :string
    add_column :users, :youtube_url, :string
    add_column :users, :facebook_url, :string
    add_column :users, :bio_visibility, :integer, default: 2
    add_column :users, :social_links_visibility, :integer, default: 2
    add_column :users, :website_visibility, :integer, default: 2

    add_index :users, :instagram_username
    add_index :users, :tiktok_username
    add_index :users, :twitter_username
  end
end
