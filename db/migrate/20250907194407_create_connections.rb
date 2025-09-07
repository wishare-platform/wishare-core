class CreateConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :connections do |t|
      t.references :user, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0

      t.timestamps
    end
    
    add_index :connections, [:user_id, :partner_id], unique: true
  end
end
