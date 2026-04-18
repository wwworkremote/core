class LlmChatResponseJob < ApplicationJob
  def perform(llm_chat_id, content)
    llm_chat = LlmChat.find(llm_chat_id)

    llm_chat.ask(content) do |chunk|
      if chunk.content && !chunk.content.empty?
        llm_message = llm_chat.llm_messages.last
        llm_message.broadcast_append_chunk(chunk.content)
      end
    end
  end
end
