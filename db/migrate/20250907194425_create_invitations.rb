class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.string :recipient_email, null: false
      t.string :token, null: false
      t.integer :status, default: 0
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :recipient_email
  end
end
