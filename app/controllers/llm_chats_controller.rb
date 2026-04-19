class LlmChatsController < ApplicationController
  before_action :set_llm_chat, only: [ :show, :destroy ]

  def index
    @llm_chats = LlmChat.order(created_at: :desc)
  end

  def new
    @llm_chat = LlmChat.new
    @chat_models = available_chat_models
    @selected_model = params[:model] || @chat_models.first&.id
  end

  def create
    prompt = params.dig(:llm_chat, :prompt)
    if prompt.present?
      @llm_chat = LlmChat.create!(model: params.dig(:llm_chat, :model).presence)
      LlmChatResponseJob.perform_later(@llm_chat.id, prompt)

      redirect_to @llm_chat, notice: "Llmchat was successfully created."
    end
  end

  def show
    @llm_message = @llm_chat.llm_messages.build
  end

  def destroy
    @llm_chat.destroy!
    redirect_to llm_chats_path, notice: "Llmchat was successfully destroyed.", status: :see_other
  end

  private

  def set_llm_chat
    @llm_chat = LlmChat.find(params[:id])
  end
end
