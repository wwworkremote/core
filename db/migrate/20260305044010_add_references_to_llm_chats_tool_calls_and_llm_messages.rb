# frozen_string_literal: true

class AddReferencesToLLMChatsToolCallsAndLLMMessages < ActiveRecord::Migration[8.0]
  def change
    add_reference :llm_chats, :model, foreign_key: true
    add_reference :tool_calls, :llm_message, null: true, foreign_key: true
    add_reference :llm_messages, :llm_chat, null: true, foreign_key: true
    add_reference :llm_messages, :model, foreign_key: true
    add_reference :llm_messages, :tool_call, foreign_key: true
  end
end
