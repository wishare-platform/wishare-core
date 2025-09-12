# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_12_065809) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_events", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "event_type", null: false
    t.json "metadata"
    t.string "session_id"
    t.inet "ip_address"
    t.text "user_agent"
    t.string "page_path"
    t.string "page_title"
    t.string "referrer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["session_id"], name: "index_analytics_events_on_session_id"
    t.index ["user_id", "event_type"], name: "index_analytics_events_on_user_id_and_event_type"
    t.index ["user_id"], name: "index_analytics_events_on_user_id"
  end

  create_table "connections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "partner_id", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["partner_id"], name: "index_connections_on_partner_id"
    t.index ["user_id", "partner_id"], name: "index_connections_on_user_id_and_partner_id", unique: true
    t.index ["user_id"], name: "index_connections_on_user_id"
  end

  create_table "cookie_consents", force: :cascade do |t|
    t.bigint "user_id"
    t.boolean "analytics_enabled", default: false
    t.boolean "marketing_enabled", default: false
    t.boolean "functional_enabled", default: true
    t.datetime "consent_date", null: false
    t.inet "ip_address"
    t.string "session_id"
    t.string "consent_version", default: "1.0"
    t.text "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consent_date"], name: "index_cookie_consents_on_consent_date"
    t.index ["session_id"], name: "index_cookie_consents_on_session_id"
    t.index ["user_id"], name: "index_cookie_consents_on_user_id"
    t.index ["user_id"], name: "index_cookie_consents_on_user_id_custom"
  end

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.integer "platform", null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_device_tokens_on_active"
    t.index ["last_used_at"], name: "index_device_tokens_on_last_used_at"
    t.index ["user_id", "platform"], name: "index_device_tokens_on_user_id_and_platform"
    t.index ["user_id", "token"], name: "index_device_tokens_on_user_id_and_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.string "recipient_email", null: false
    t.string "token", null: false
    t.integer "status", default: 0
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_email"], name: "index_invitations_on_recipient_email"
    t.index ["sender_id"], name: "index_invitations_on_sender_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "email_invitations", default: true, null: false
    t.boolean "email_purchases", default: true, null: false
    t.boolean "email_new_items", default: false, null: false
    t.boolean "email_connections", default: true, null: false
    t.boolean "push_enabled", default: false, null: false
    t.integer "digest_frequency", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.integer "notification_type"
    t.string "title"
    t.text "message"
    t.boolean "read", default: false, null: false
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "digest_processed_at"
    t.string "digest_frequency_sent"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.string "channel_hash"
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "user_analytics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "wishlists_created_count", default: 0
    t.integer "items_added_count", default: 0
    t.integer "connections_count", default: 0
    t.integer "invitations_sent_count", default: 0
    t.integer "invitations_accepted_count", default: 0
    t.integer "items_purchased_count", default: 0
    t.integer "page_views_count", default: 0
    t.datetime "last_activity_at"
    t.datetime "first_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_activity_at"], name: "index_user_analytics_on_last_activity_at"
    t.index ["user_id"], name: "index_user_analytics_on_user_id"
    t.index ["user_id"], name: "index_user_analytics_on_user_id_unique", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "avatar_url"
    t.date "date_of_birth"
    t.string "preferred_locale", default: "en"
    t.integer "role", default: 0, null: false
    t.text "street_address"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country", limit: 2
    t.integer "address_visibility", default: 0, null: false
    t.string "street_number"
    t.string "apartment_unit"
    t.string "theme_preference", default: "system"
    t.index ["address_visibility"], name: "index_users_on_address_visibility"
    t.index ["country"], name: "index_users_on_country"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["postal_code"], name: "index_users_on_postal_code"
    t.index ["preferred_locale"], name: "index_users_on_preferred_locale"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "wishlist_items", force: :cascade do |t|
    t.bigint "wishlist_id", null: false
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.string "url"
    t.string "image_url"
    t.integer "priority"
    t.integer "status"
    t.bigint "purchased_by_id"
    t.datetime "purchased_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "currency", limit: 3, default: "USD"
    t.index ["currency"], name: "index_wishlist_items_on_currency"
    t.index ["purchased_by_id"], name: "index_wishlist_items_on_purchased_by_id"
    t.index ["wishlist_id"], name: "index_wishlist_items_on_wishlist_id"
  end

  create_table "wishlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.text "description"
    t.boolean "is_default"
    t.integer "visibility"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "event_date"
    t.string "event_type"
    t.index ["user_id"], name: "index_wishlists_on_user_id"
  end

  add_foreign_key "analytics_events", "users"
  add_foreign_key "connections", "users"
  add_foreign_key "connections", "users", column: "partner_id"
  add_foreign_key "cookie_consents", "users"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "invitations", "users", column: "sender_id"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "user_analytics", "users"
  add_foreign_key "wishlist_items", "users", column: "purchased_by_id"
  add_foreign_key "wishlist_items", "wishlists"
  add_foreign_key "wishlists", "users"
end
