class LLMMessagesController < ApplicationController
  before_action :set_llm_chat

  def create
    content = params.dig(:llm_message, :content)
    if content.present?
      @llm_message = @llm_chat.llm_messages.create!(role: "user", content: content)
      LLMChatResponseJob.perform_later(@llm_chat.id, content)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @llm_chat }
      end
    end
  end

  private

  def set_llm_chat
    @llm_chat = LLMChat.find(params[:llm_chat_id])
  end
end
