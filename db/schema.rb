# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 20_210_707_203_641) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'citext'
  enable_extension 'hstore'
  enable_extension 'ltree'
  enable_extension 'pg_stat_statements'
  enable_extension 'pg_trgm'
  enable_extension 'pgcrypto'
  enable_extension 'plpgsql'
  enable_extension 'sslinfo'

  create_table 'messages', force: :cascade do |t|
    t.jsonb 'data', default: {}, null: false
    t.integer 'status', default: 0
    t.datetime 'created_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    t.datetime 'updated_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
  end

  create_table 'notifications_request_faradays', force: :cascade do |t|
    t.string 'signature', null: false
    t.jsonb 'event', default: {}, null: false
    t.jsonb 'payload', default: {}, null: false
    t.datetime 'created_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    t.datetime 'updated_at', precision: 6, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    t.index ['signature'], name: 'index_notifications_request_faradays_on_signature', unique: true
  end
end
