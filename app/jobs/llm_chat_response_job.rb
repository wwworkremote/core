# frozen_string_literal: true

class LLMChatResponseJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(chat_id, _content) { "chat/#{chat_id}" }

  def perform(llm_chat_id, content)
    llm_chat = LLMChat.find(llm_chat_id)
    result = request_response(llm_chat, content)
    handle_result(llm_chat, result)
  end

  private

  # Use Orchestrator for guardrails, safety, and streaming. Orchestrator
  # now handles placeholder creation and internal streaming broadcasts.
  # rubocop:disable Metrics/MethodLength
  def request_response(llm_chat, content)
    LLM::Orchestrator.call(
      untrusted_text: content,
      chat: llm_chat,
      model: llm_chat.model,
      system_rules: "You are a helpful assistant.",
      task_instructions: "Respond to the user's message based on our conversation history.",
      metadata: { llm_chat_id: llm_chat.id }
    )
  end
  # rubocop:enable Metrics/MethodLength

  def handle_result(llm_chat, result)
    return broadcast_final_message(llm_chat) if result[:success]

    Rails.logger.error "[LLMChatResponseJob] Orchestrator failed: #{result[:error]}"
  end

  # After streaming is complete, replace the entire message with the fully rendered markdown version
  def broadcast_final_message(llm_chat)
    final_message = llm_chat.llm_messages.where(role: "assistant").last
    final_message&.broadcast_replace_to "llm_chat_#{llm_chat.id}"
  end
end
