class CreateCookieConsents < ActiveRecord::Migration[8.0]
  def change
    create_table :cookie_consents do |t|
      t.references :user, null: true, foreign_key: true # Allow anonymous consent
      t.boolean :analytics_enabled, default: false
      t.boolean :marketing_enabled, default: false
      t.boolean :functional_enabled, default: true # Required for site functionality
      t.datetime :consent_date, null: false
      t.inet :ip_address
      t.string :session_id # Track anonymous users
      t.string :consent_version, default: '1.0' # Track consent policy version
      t.text :user_agent

      t.timestamps
    end

    add_index :cookie_consents, :user_id, name: 'index_cookie_consents_on_user_id_custom'
    add_index :cookie_consents, :session_id
    add_index :cookie_consents, :consent_date
  end
end
