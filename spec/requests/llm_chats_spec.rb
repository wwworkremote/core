# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LLM Chats", type: :request do
  let!(:model) { create(:model) }
  let!(:chat) { LLMChat.create!(model: model) }
  let(:chat_params) do
    {
      llm_chat: {
        model_id: model.id,
        prompt: "Starting a new chat"
      }
    }
  end

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "GET /llm_chats" do
    it "returns a success response" do
      get llm_chats_path
      expect(response).to be_successful
    end
  end

  describe "GET /llm_chats/:id" do
    it "returns a success response" do
      get llm_chat_path(chat)
      expect(response).to be_successful
    end
  end

  describe "GET /llm_chats/new" do
    it "returns a success response" do
      get new_llm_chat_path
      expect(response).to be_successful
    end
  end

  describe "POST /llm_chats" do
    it "creates a new LLMChat and redirects" do
      expect {
        post llm_chats_path, params: chat_params
      }.to change(LLMChat, :count).by(1)
       .and change(LLMMessage, :count).by(1)
       .and have_enqueued_job(LLMChatResponseJob)

      expect(response).to redirect_to(llm_chat_path(LLMChat.last))
      follow_redirect!
      expect(response.body).to include("Neural link established.")
    end

    it "redirects to new on invalid params" do
      post llm_chats_path, params: { llm_chat: { model_id: nil, prompt: "" } }
      expect(response).to redirect_to(new_llm_chat_path)
    end
  end

  describe "DELETE /llm_chats/:id" do
    it "destroys the LLMChat and redirects" do
      expect {
        delete llm_chat_path(chat)
      }.to change(LLMChat, :count).by(-1)

      expect(response).to redirect_to(llm_chats_path)
    end
  end
end
