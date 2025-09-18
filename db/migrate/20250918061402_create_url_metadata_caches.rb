class CreateUrlMetadataCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :url_metadata_caches do |t|
      t.string :url, null: false
      t.string :normalized_url, null: false
      t.string :url_hash, null: false
      t.string :title
      t.text :description
      t.string :image_url
      t.decimal :price, precision: 10, scale: 2
      t.string :currency
      t.string :platform
      t.string :extraction_method
      t.json :metadata
      t.integer :hit_count, default: 0, null: false
      t.datetime :last_accessed_at
      t.datetime :extracted_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :url_metadata_caches, :url
    add_index :url_metadata_caches, :normalized_url
    add_index :url_metadata_caches, :url_hash, unique: true
    add_index :url_metadata_caches, :expires_at
    add_index :url_metadata_caches, :platform
    add_index :url_metadata_caches, [:hit_count, :last_accessed_at], name: 'index_url_caches_on_popularity'
  end
end
