# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LLM Messages", type: :request do
  let!(:model) { create(:model) }
  let!(:chat) { LLMChat.create!(model: model) }
  let(:message_params) { { llm_message: { content: "Hello AI" } } }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "POST /llm_chats/:llm_chat_id/llm_messages" do
    it "creates a user message and enqueues a response job" do
      expect {
        post llm_chat_llm_messages_path(chat), params: message_params
      }.to change(LLMMessage, :count).by(1)
       .and have_enqueued_job(LLMChatResponseJob)

      expect(response).to redirect_to(llm_chat_path(chat))
    end

    it "handles turbo stream requests" do
      post llm_chat_llm_messages_path(chat), params: message_params, as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response).to be_successful
    end
  end
end
