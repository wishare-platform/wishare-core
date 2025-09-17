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

ActiveRecord::Schema[8.0].define(version: 2025_09_17_183412) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "content", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id", "created_at"], name: "idx_on_commentable_type_commentable_id_created_at_b19869655b"
    t.index ["commentable_type", "commentable_id"], name: "index_activity_comments_on_commentable"
    t.index ["parent_id"], name: "index_activity_comments_on_parent_id"
    t.index ["user_id", "created_at"], name: "index_activity_comments_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_activity_comments_on_user_id"
  end

  create_table "activity_feeds", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "actor_id", null: false
    t.string "action_type", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.json "metadata"
    t.boolean "is_public", default: true
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type", "occurred_at"], name: "index_activity_feeds_on_action_type_and_occurred_at"
    t.index ["actor_id", "occurred_at"], name: "index_activity_feeds_on_actor_id_and_occurred_at"
    t.index ["actor_id"], name: "index_activity_feeds_on_actor_id"
    t.index ["is_public", "occurred_at"], name: "index_activity_feeds_on_is_public_and_occurred_at"
    t.index ["target_type", "target_id"], name: "index_activity_feeds_on_target"
    t.index ["target_type", "target_id"], name: "index_activity_feeds_on_target_type_and_target_id"
    t.index ["user_id", "occurred_at"], name: "index_activity_feeds_on_user_id_and_occurred_at"
    t.index ["user_id"], name: "index_activity_feeds_on_user_id"
  end

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

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylists_on_exp"
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
    t.index ["user_id"], name: "index_jwt_denylists_on_user_id"
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

  create_table "share_analytics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "shareable_type", null: false
    t.bigint "shareable_id", null: false
    t.string "platform", null: false
    t.datetime "shared_at", null: false
    t.integer "clicks", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform"], name: "index_share_analytics_on_platform"
    t.index ["shareable_type", "shareable_id"], name: "index_share_analytics_on_shareable_type_and_shareable_id"
    t.index ["shared_at"], name: "index_share_analytics_on_shared_at"
    t.index ["user_id", "platform"], name: "index_share_analytics_on_user_id_and_platform"
    t.index ["user_id"], name: "index_share_analytics_on_user_id"
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

  create_table "user_interactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "interaction_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interaction_type", "created_at"], name: "index_user_interactions_on_interaction_type_and_created_at"
    t.index ["target_type", "target_id", "interaction_type"], name: "idx_on_target_type_target_id_interaction_type_7aa7a94514"
    t.index ["target_type", "target_id"], name: "index_user_interactions_on_target"
    t.index ["user_id", "target_type", "target_id"], name: "index_user_interactions_uniqueness", unique: true
    t.index ["user_id"], name: "index_user_interactions_on_user_id"
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
    t.jsonb "device_info", default: {}
    t.text "bio"
    t.string "website"
    t.integer "gender", default: 0
    t.string "instagram_username"
    t.string "tiktok_username"
    t.string "twitter_username"
    t.string "linkedin_url"
    t.string "youtube_url"
    t.string "facebook_url"
    t.integer "bio_visibility", default: 2
    t.integer "social_links_visibility", default: 2
    t.integer "website_visibility", default: 2
    t.index ["address_visibility"], name: "index_users_on_address_visibility"
    t.index ["country"], name: "index_users_on_country"
    t.index ["device_info"], name: "index_users_on_device_info", using: :gin
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["instagram_username"], name: "index_users_on_instagram_username"
    t.index ["postal_code"], name: "index_users_on_postal_code"
    t.index ["preferred_locale"], name: "index_users_on_preferred_locale"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["tiktok_username"], name: "index_users_on_tiktok_username"
    t.index ["twitter_username"], name: "index_users_on_twitter_username"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_comments", "activity_comments", column: "parent_id"
  add_foreign_key "activity_comments", "users"
  add_foreign_key "activity_feeds", "users"
  add_foreign_key "activity_feeds", "users", column: "actor_id"
  add_foreign_key "analytics_events", "users"
  add_foreign_key "connections", "users"
  add_foreign_key "connections", "users", column: "partner_id"
  add_foreign_key "cookie_consents", "users"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "invitations", "users", column: "sender_id"
  add_foreign_key "jwt_denylists", "users"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "share_analytics", "users"
  add_foreign_key "user_analytics", "users"
  add_foreign_key "user_interactions", "users"
  add_foreign_key "wishlist_items", "users", column: "purchased_by_id"
  add_foreign_key "wishlist_items", "wishlists"
  add_foreign_key "wishlists", "users"
end
