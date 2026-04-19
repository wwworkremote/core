class LlmChatResponseJob < ApplicationJob
  def perform(llm_chat_id, content)
    llm_chat = LlmChat.find(llm_chat_id)

    # Use Orchestrator for guardrails, safety, and streaming
    result = Llm::Orchestrator.call(
      untrusted_text: content,
      model: llm_chat.model,
      system_rules: "You are a helpful assistant.",
      task_instructions: "Respond to the user's message based on our conversation history.",
      metadata: { llm_chat_id: llm_chat.id }
    ) do |chunk|
      if chunk.content.present?
        llm_message = llm_chat.llm_messages.last
        llm_message.broadcast_append_chunk(chunk.content)
      end
    end

    if result[:success]
      # After streaming is complete, replace the entire message with the fully rendered markdown version
      final_message = llm_chat.llm_messages.last
      if final_message&.assistant?
        final_message.broadcast_replace_to "llm_chat_#{llm_chat.id}"
      end
    else
      Rails.logger.error "[LlmChatResponseJob] Orchestrator failed: #{result[:error]}"
      # We could also broadcast an error message here
    end
  end
end
