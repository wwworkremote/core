# frozen_string_literal: true

class LLMChatsController < ApplicationController
  before_action :set_llm_chat, only: %i[show destroy]

  def index
    @llm_chats = LLMChat.order(created_at: :desc)
  end

  def show
    @llm_message = @llm_chat.llm_messages.build
  end

  def new
    @llm_chat = LLMChat.new
    @chat_models = available_chat_models
    @selected_model = params[:model] || @chat_models.first&.id
  end

  def create
    prompt = params.dig(:llm_chat, :prompt)
    model_record = Model.find_by(id: params.dig(:llm_chat, :model_id))

    if prompt.present? && model_record
      @llm_chat = LLMChat.create!(model: model_record)
      @llm_chat.llm_messages.create!(role: "user", content: prompt)
      LLMChatResponseJob.perform_later(@llm_chat.id, prompt)

      redirect_to @llm_chat, notice: "Neural link established."
    else
      redirect_to new_llm_chat_path, alert: "Invalid model or empty prompt."
    end
  end

  def destroy
    @llm_chat.destroy!
    redirect_to llm_chats_path, notice: "LLMchat was successfully destroyed.", status: :see_other
  end

  private

  def set_llm_chat
    @llm_chat = LLMChat.find(params.expect(:id))
  end
end
