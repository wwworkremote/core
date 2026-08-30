# frozen_string_literal: true

# == Schema Information
#
# Table name: extension_error_events
#
#  id                   :bigint           not null, primary key
#  build_version        :string           not null
#  context              :jsonb            not null
#  error_message        :text
#  error_name           :string
#  event_name           :string           not null
#  guided_session_token :string
#  occurred_at          :datetime         not null
#  page_host            :string
#  phase                :string
#  provider             :string
#  recoverable          :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  trace_id             :string
#
# Indexes
#
#  index_extension_error_events_on_event_name_and_occurred_at  (event_name,occurred_at)
#  index_extension_error_events_on_guided_session_token        (guided_session_token)
#  index_extension_error_events_on_trace_id                    (trace_id)
#
class ExtensionErrorEvent < ApplicationRecord
  validates :build_version, :event_name, :occurred_at, presence: true
end
