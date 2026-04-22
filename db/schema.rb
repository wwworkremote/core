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

ActiveRecord::Schema[8.0].define(version: 2026_04_22_223825) do
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
  enable_extension "vector"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.bigint "user_id"
    t.bigint "visit_id"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "app_version"
    t.string "browser"
    t.string "city"
    t.string "country"
    t.string "device_type"
    t.string "ip"
    t.text "landing_page"
    t.float "latitude"
    t.float "longitude"
    t.string "os"
    t.string "os_version"
    t.string "platform"
    t.text "referrer"
    t.string "referring_domain"
    t.string "region"
    t.datetime "started_at"
    t.text "user_agent"
    t.bigint "user_id"
    t.string "utm_campaign"
    t.string "utm_content"
    t.string "utm_medium"
    t.string "utm_source"
    t.string "utm_term"
    t.string "visit_token"
    t.string "visitor_token"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

  create_table "board_queries", force: :cascade do |t|
    t.string "board_name"
    t.text "terms"
    t.boolean "remote"
    t.integer "priority"
    t.json "query_params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "career_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "resume_text"
    t.text "goals"
    t.text "skills"
    t.string "experience_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "contact_info"
    t.jsonb "location_info"
    t.vector "embedding", limit: 3584
    t.string "github_url"
    t.jsonb "github_context"
    t.index ["user_id"], name: "index_career_profiles_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "glassdoor_data"
    t.float "sentiment_score"
    t.string "disposition"
    t.boolean "toxic_culture_flag"
    t.index ["slug"], name: "index_companies_on_slug"
  end

  create_table "company_pipeline_steps", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "status"
    t.text "note"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["company_id"], name: "index_company_pipeline_steps_on_company_id"
    t.index ["user_id"], name: "index_company_pipeline_steps_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "role"
    t.string "relationship_type"
    t.bigint "job_posting_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["job_posting_id"], name: "index_contacts_on_job_posting_id"
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "discovery_links", force: :cascade do |t|
    t.string "board_name"
    t.string "url"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "error_message"
    t.index ["url"], name: "index_discovery_links_on_url"
  end

  create_table "domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.citext "name", null: false
    t.bigint "root_domain_id"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "email_import_records", force: :cascade do |t|
    t.string "message_id"
    t.string "file_path"
    t.string "file_checksum"
    t.string "source"
    t.string "status"
    t.text "error_message"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_checksum"], name: "index_email_import_records_on_file_checksum"
    t.index ["message_id"], name: "index_email_import_records_on_message_id"
  end

  create_table "emails", force: :cascade do |t|
    t.citext "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_emails_on_address", unique: true
  end

  create_table "event_store_events", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.binary "data", null: false
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.binary "metadata"
    t.datetime "valid_at", precision: nil
    t.index ["created_at"], name: "index_event_store_events_on_created_at"
    t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_event_store_events_on_event_type"
    t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
  end

  create_table "event_store_events_in_streams", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.uuid "event_id", null: false
    t.integer "position"
    t.string "stream", null: false
    t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
    t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
    t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
  end

  create_table "experience_highlights", force: :cascade do |t|
    t.bigint "work_experience_id", null: false
    t.string "label"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_experience_id"], name: "index_experience_highlights_on_work_experience_id"
  end

  create_table "hacker_news_items", id: false, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}
    t.integer "id", null: false
    t.integer "schema", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_hacker_news_items_on_id", unique: true
    t.index ["schema"], name: "index_hacker_news_items_on_schema"
    t.index ["state"], name: "index_hacker_news_items_on_state"
  end

  create_table "hacker_news_v0_jobstories", id: false, force: :cascade do |t|
    t.string "by"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "id", null: false
    t.integer "score"
    t.text "text"
    t.integer "time"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["id"], name: "index_hacker_news_v0_jobstories_on_id", unique: true
  end

  create_table "job_boards_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "aasm_state"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "document", default: "", null: false
    t.integer "job_boards_query_id", null: false
    t.string "signature"
    t.integer "source_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["job_boards_query_id"], name: "index_job_boards_documents_on_job_boards_query_id"
    t.index ["signature"], name: "index_job_boards_documents_on_signature", unique: true
    t.index ["source_id"], name: "index_job_boards_documents_on_source_id"
  end

  create_table "job_boards_queries", force: :cascade do |t|
    t.string "aasm_state"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["source_id"], name: "index_job_boards_queries_on_source_id"
  end

  create_table "job_boards_sources", force: :cascade do |t|
    t.string "aasm_state"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data", default: {}, null: false
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "last_synced_at"
    t.datetime "last_ingested_at"
    t.index ["slug"], name: "index_job_boards_sources_on_slug", unique: true
  end

  create_table "job_experiences", force: :cascade do |t|
    t.bigint "career_profile_id", null: false
    t.string "title"
    t.string "company"
    t.date "start_date"
    t.date "end_date"
    t.boolean "current"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["career_profile_id"], name: "index_job_experiences_on_career_profile_id"
  end

  create_table "job_postings", force: :cascade do |t|
    t.string "body"
    t.string "company"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.vector "embedding", limit: 3584
    t.string "external_author_id"
    t.string "external_id"
    t.float "latitude"
    t.string "location"
    t.float "longitude"
    t.datetime "published_at"
    t.string "signature", null: false
    t.bigint "source_id"
    t.string "tags", array: true
    t.string "target_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "status"
    t.datetime "enriched_at"
    t.string "crawl_status"
    t.index ["body"], name: "index_job_postings_on_body", opclass: :gin_trgm_ops, using: :gin
    t.index ["company", "published_at"], name: "index_job_postings_on_company_and_published_at", order: { published_at: :desc }
    t.index ["company"], name: "index_job_postings_on_company"
    t.index ["data"], name: "index_job_postings_on_data", opclass: :jsonb_path_ops, using: :gin
    t.index ["external_id"], name: "index_job_postings_on_external_id"
    t.index ["location"], name: "index_job_postings_on_location"
    t.index ["published_at"], name: "index_job_postings_on_published_at"
    t.index ["source_id", "published_at"], name: "index_job_postings_on_source_id_and_published_at", order: { published_at: :desc }
    t.index ["source_id"], name: "index_job_postings_on_source_id"
    t.index ["title"], name: "index_job_postings_on_title", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "llm_chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "model_id"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_llm_chats_on_model_id"
  end

  create_table "llm_messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "llm_chat_id"
    t.bigint "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.text "thinking_signature"
    t.text "thinking_text"
    t.integer "thinking_tokens"
    t.bigint "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["llm_chat_id"], name: "index_llm_messages_on_llm_chat_id"
    t.index ["model_id"], name: "index_llm_messages_on_model_id"
    t.index ["role"], name: "index_llm_messages_on_role"
    t.index ["tool_call_id"], name: "index_llm_messages_on_tool_call_id"
  end

  create_table "messages", force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["subject"], name: "index_messages_on_subject"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "models", force: :cascade do |t|
    t.jsonb "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.jsonb "metadata", default: {}
    t.jsonb "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.jsonb "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["capabilities"], name: "index_models_on_capabilities", using: :gin
    t.index ["family"], name: "index_models_on_family"
    t.index ["modalities"], name: "index_models_on_modalities", using: :gin
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
  end

  create_table "origins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.citext "name"
    t.datetime "updated_at", null: false
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "searchable_id"
    t.string "searchable_type"
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.text "database"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.text "user"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pipeline_steps", force: :cascade do |t|
    t.bigint "job_posting_id", null: false
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "link"
    t.text "note"
    t.bigint "user_id"
    t.index ["job_posting_id"], name: "index_pipeline_steps_on_job_posting_id"
    t.index ["user_id"], name: "index_pipeline_steps_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.string "name"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "event", default: {}, null: false
    t.bigint "origin_id"
    t.jsonb "payload", default: {}, null: false
    t.string "signature", null: false
    t.datetime "updated_at", null: false
    t.index ["event"], name: "index_sources_on_event", opclass: :jsonb_path_ops, using: :gin
    t.index ["origin_id"], name: "index_sources_on_origin_id"
    t.index ["payload"], name: "index_sources_on_payload", opclass: :jsonb_path_ops, using: :gin
    t.index ["signature"], name: "index_sources_on_signature", unique: true
  end

  create_table "system_settings", force: :cascade do |t|
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_system_settings_on_key"
  end

  create_table "target_domains", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.bigint "job_posting_id", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id", "job_posting_id"], name: "index_target_domains_on_domain_id_and_job_posting_id", unique: true
    t.index ["job_posting_id", "domain_id"], name: "index_target_domains_on_job_posting_id_and_domain_id", unique: true
  end

  create_table "tool_calls", force: :cascade do |t|
    t.jsonb "arguments", default: {}
    t.datetime "created_at", null: false
    t.bigint "llm_message_id"
    t.string "name", null: false
    t.string "thought_signature"
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["llm_message_id"], name: "index_tool_calls_on_llm_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  create_table "user_job_postings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "job_posting_id", null: false
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "match_analysis"
    t.boolean "priority_flag"
    t.index ["job_posting_id"], name: "index_user_job_postings_on_job_posting_id"
    t.index ["user_id"], name: "index_user_job_postings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "name", null: false
    t.string "password_digest"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "work_experiences", force: :cascade do |t|
    t.bigint "career_profile_id", null: false
    t.string "company_name"
    t.string "location"
    t.string "title"
    t.string "employment_type"
    t.date "start_date"
    t.date "end_date"
    t.text "context"
    t.text "description"
    t.text "summary"
    t.text "action"
    t.text "impact"
    t.jsonb "scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.index ["career_profile_id"], name: "index_work_experiences_on_career_profile_id"
    t.index ["external_id"], name: "index_work_experiences_on_external_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "career_profiles", "users"
  add_foreign_key "company_pipeline_steps", "companies"
  add_foreign_key "company_pipeline_steps", "users"
  add_foreign_key "contacts", "job_postings"
  add_foreign_key "contacts", "users"
  add_foreign_key "experience_highlights", "work_experiences"
  add_foreign_key "job_experiences", "career_profiles"
  add_foreign_key "job_postings", "sources"
  add_foreign_key "llm_chats", "models"
  add_foreign_key "llm_messages", "llm_chats"
  add_foreign_key "llm_messages", "models"
  add_foreign_key "llm_messages", "tool_calls"
  add_foreign_key "pipeline_steps", "job_postings"
  add_foreign_key "pipeline_steps", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "sources", "origins"
  add_foreign_key "target_domains", "domains"
  add_foreign_key "target_domains", "job_postings"
  add_foreign_key "tool_calls", "llm_messages"
  add_foreign_key "user_job_postings", "job_postings"
  add_foreign_key "user_job_postings", "users"
  add_foreign_key "work_experiences", "career_profiles"
end
