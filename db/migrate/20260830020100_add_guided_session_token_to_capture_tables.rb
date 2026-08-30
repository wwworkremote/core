# frozen_string_literal: true

# Correlation spine (ADR 010 §2): during a guided session the extension stamps
# the GuidedSession#session_token onto the rows it writes, and GuidedCapture
# stamps it onto the materialized Scenario. One identifier holds the whole
# coordinated run. Nullable -- non-guided capture paths never set it. No
# backfill onto historical rows.
class AddGuidedSessionTokenToCaptureTables < ActiveRecord::Migration[8.1]
  TABLES = %i[
    application_field_answers
    application_field_mappings
    application_field_observations
    extension_error_events
    scenarios
  ].freeze

  def change
    safety_assured { TABLES.each { |table| add_column table, :guided_session_token, :string } }
    safety_assured { TABLES.each { |table| add_index table, :guided_session_token } }
  end
end
