class LlmChatResponseJob < ApplicationJob
  self.queue_adapter = :async_job

  def perform(llm_chat_id, content)
    llm_chat = LlmChat.find(llm_chat_id)

    # Use Orchestrator for guardrails, safety, and streaming.
    # Orchestrator now handles placeholder creation and internal streaming broadcasts.
    result = Llm::Orchestrator.call(
      untrusted_text: content,
      chat: llm_chat,
      model: llm_chat.model,
      system_rules: "You are a helpful assistant.",
      task_instructions: "Respond to the user's message based on our conversation history.",
      metadata: { llm_chat_id: llm_chat.id }
    )

    if result[:success]
      # After streaming is complete, replace the entire message with the fully rendered markdown version
      final_message = llm_chat.llm_messages.where(role: 'assistant').last
      final_message&.broadcast_replace_to "llm_chat_#{llm_chat.id}"
    else
      Rails.logger.error "[LlmChatResponseJob] Orchestrator failed: #{result[:error]}"
    end
  end
end
