class CreateUserInteractions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_interactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target, polymorphic: true, null: false
      t.string :interaction_type, null: false
      t.timestamps
    end

    add_index :user_interactions, [:user_id, :target_type, :target_id], unique: true, name: 'index_user_interactions_uniqueness'
    add_index :user_interactions, [:target_type, :target_id, :interaction_type]
    add_index :user_interactions, [:interaction_type, :created_at]
  end
end
