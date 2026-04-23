# frozen_string_literal: true

# == Schema Information
#
# Table name: tool_calls
#
#  id                :bigint           not null, primary key
#  arguments         :jsonb
#  name              :string           not null
#  thought_signature :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  llm_message_id    :bigint
#  tool_call_id      :string           not null
#
# Indexes
#
#  index_tool_calls_on_llm_message_id  (llm_message_id)
#  index_tool_calls_on_name            (name)
#  index_tool_calls_on_tool_call_id    (tool_call_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (llm_message_id => llm_messages.id)
#
class ToolCall < ApplicationRecord
  acts_as_tool_call message: :llm_message, message_foreign_key: :llm_message_id
end
