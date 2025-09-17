class CreateActivityComments < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.text :content, null: false
      t.references :parent, foreign_key: { to_table: :activity_comments }, null: true
      t.timestamps
    end

    add_index :activity_comments, [:commentable_type, :commentable_id, :created_at]
    add_index :activity_comments, [:user_id, :created_at]
  end
end
