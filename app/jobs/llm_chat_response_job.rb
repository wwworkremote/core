class LlmChatResponseJob < ApplicationJob
  def perform(llm_chat_id, content)
    llm_chat = LlmChat.find(llm_chat_id)

    llm_chat.ask(content) do |chunk|
      if chunk.content.present?
        llm_message = llm_chat.llm_messages.last
        llm_message.broadcast_append_chunk(chunk.content)
      end
    end

    # After streaming is complete, replace the entire message with the fully rendered markdown version
    # to ensure formatting (links, code blocks, etc.) is correct.
    final_message = llm_chat.llm_messages.last
    if final_message&.assistant?
      final_message.broadcast_replace_to "llm_chat_#{llm_chat.id}"
    end
  end
end
