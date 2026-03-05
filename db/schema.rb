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

ActiveRecord::Schema[8.0].define(version: 2026_03_05_034442) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "ltree"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "sslinfo"

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "domains", force: :cascade do |t|
    t.citext "name", null: false
    t.bigint "root_domain_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "emails", force: :cascade do |t|
    t.citext "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_emails_on_address", unique: true
  end

  create_table "event_store_events", force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.binary "data", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "valid_at", precision: nil
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.string "stream", null: false
    t.integer "position"
    t.uuid "event_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "hacker_news_items", id: false, force: :cascade do |t|
    t.integer "id", null: false
    t.integer "schema", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "data", default: {}
    t.index ["id"], name: "index_hacker_news_items_on_id", unique: true
    t.index ["schema"], name: "index_hacker_news_items_on_schema"
    t.index ["state"], name: "index_hacker_news_items_on_state"
  end

  create_table "hacker_news_v0_jobstories", id: false, force: :cascade do |t|
    t.integer "id", null: false
    t.string "by"
    t.integer "score"
    t.integer "time"
    t.string "title"
    t.string "url"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "text"
    t.index ["id"], name: "index_hacker_news_v0_jobstories_on_id", unique: true
  end

  create_table "job_boards_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "source_id", null: false
    t.integer "job_boards_query_id", null: false
    t.text "document", default: "", null: false
    t.string "signature"
    t.string "aasm_state"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["job_boards_query_id"], name: "index_job_boards_documents_on_job_boards_query_id"
    t.index ["signature"], name: "index_job_boards_documents_on_signature", unique: true
    t.index ["source_id"], name: "index_job_boards_documents_on_source_id"
  end

  create_table "job_boards_queries", force: :cascade do |t|
    t.integer "source_id", null: false
    t.jsonb "data", default: {}, null: false
    t.string "aasm_state"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["source_id"], name: "index_job_boards_queries_on_source_id"
  end

  create_table "job_boards_sources", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.jsonb "data", default: {}, null: false
    t.string "aasm_state"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["slug"], name: "index_job_boards_sources_on_slug", unique: true
  end

  create_table "job_postings", force: :cascade do |t|
    t.string "signature", null: false
    t.bigint "source_id"
    t.string "title"
    t.string "body"
    t.string "company"
    t.string "location"
    t.string "external_author_id"
    t.string "external_id"
    t.datetime "published_at"
    t.string "tags", array: true
    t.string "target_url"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.index ["source_id"], name: "index_job_postings_on_source_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "subject", null: false
    t.string "body", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject"], name: "index_messages_on_subject"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "origins", force: :cascade do |t|
    t.citext "name"
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.text "database"
    t.text "user"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "sources", force: :cascade do |t|
    t.string "signature", null: false
    t.jsonb "event", default: {}, null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "origin_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["origin_id"], name: "index_sources_on_origin_id"
    t.index ["signature"], name: "index_sources_on_signature", unique: true
  end

  create_table "target_domains", force: :cascade do |t|
    t.bigint "job_posting_id", null: false
    t.bigint "domain_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id", "job_posting_id"], name: "index_target_domains_on_domain_id_and_job_posting_id", unique: true
    t.index ["domain_id"], name: "index_target_domains_on_domain_id"
    t.index ["job_posting_id", "domain_id"], name: "index_target_domains_on_job_posting_id_and_domain_id", unique: true
    t.index ["job_posting_id"], name: "index_target_domains_on_job_posting_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "email", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "job_postings", "sources"
  add_foreign_key "sources", "origins"
  add_foreign_key "target_domains", "domains"
  add_foreign_key "target_domains", "job_postings"
end
