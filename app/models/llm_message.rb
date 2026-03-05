class LlmMessage < ApplicationRecord
  include RubyLLM::ActiveRecord::ActsAs
  acts_as_message chat: :llm_chat, chat_foreign_key: :llm_chat_id, tool_calls_foreign_key: :llm_message_id
  has_many_attached :attachments
end
