class CreateCoupleUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :couple_users do |t|
      t.references :couple, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
