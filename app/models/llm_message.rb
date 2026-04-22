# == Schema Information
#
# Table name: llm_messages
#
#  id                    :bigint           not null, primary key
#  cache_creation_tokens :integer
#  cached_tokens         :integer
#  content               :text
#  content_raw           :json
#  input_tokens          :integer
#  output_tokens         :integer
#  role                  :string           not null
#  thinking_signature    :text
#  thinking_text         :text
#  thinking_tokens       :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  llm_chat_id           :bigint
#  model_id              :bigint
#  tool_call_id          :bigint
#
# Indexes
#
#  index_llm_messages_on_llm_chat_id   (llm_chat_id)
#  index_llm_messages_on_model_id      (model_id)
#  index_llm_messages_on_role          (role)
#  index_llm_messages_on_tool_call_id  (tool_call_id)
#
# Foreign Keys
#
#  fk_rails_...  (llm_chat_id => llm_chats.id)
#  fk_rails_...  (model_id => models.id)
#  fk_rails_...  (tool_call_id => tool_calls.id)
#
class LLMMessage < ApplicationRecord
  include ::RubyLLM::ActiveRecord::ActsAs
  acts_as_message chat: :llm_chat, chat_foreign_key: :llm_chat_id, tool_calls_foreign_key: :llm_message_id
  has_many_attached :attachments

  broadcasts_to ->(llm_message) { "llm_chat_#{llm_message.llm_chat_id}" }, inserts_by: :append, on: :create

  def broadcast_append_chunk(content)
    broadcast_append_to "llm_chat_#{llm_chat_id}",
      target: "llm_message_#{id}_content",
      content: ERB::Util.html_escape(content.to_s)
  end
end
