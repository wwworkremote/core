# frozen_string_literal: true

# == Schema Information
#
# Table name: llm_chats
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  model_id   :bigint
#
# Indexes
#
#  index_llm_chats_on_model_id  (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id)
#
class LLMChat < ApplicationRecord
  include ::RubyLLM::ActiveRecord::ActsAs

  acts_as_chat messages: :llm_messages, messages_foreign_key: :llm_chat_id
end
