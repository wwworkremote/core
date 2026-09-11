# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Neural Dialogue UX", :js do
  include ActiveJob::TestHelper

  before do
    driven_by :cuprite
  end

  let!(:model) { create(:model, name: "Llama Local", model_id: "llama3.2:latest") }
  let(:user) { User.find_or_create_by!(email: "mike@just3ws.com") { |u| u.name = "Mike"; u.password = "password" } }

  def stub_llm_response(content)
    sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{content.to_json}}}]}\n\ndata: [DONE]\n"
    stub_request(:post, "http://localhost:11500/v1/chat/completions")
      .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })
  end

  it "allows a user to start a dialogue and receive a simulated response" do
    visit new_llm_chat_path

    select model.name, from: "llm_chat[model_id]"
    fill_in "llm_chat[prompt]", with: "Explain Ruby blocks."
    stub_llm_response("Ruby blocks are chunks of code.")

    click_button "Start Chat"
    expect(page).to have_text(/Neural link established/i)

    # Manually trigger the response job
    chat = LLMChat.last
    LLMChatResponseJob.perform_now(chat.id, "Explain Ruby blocks.")

    # Verify message was created in DB
    expect(chat.llm_messages.where(role: "assistant").last.content).to include("Ruby blocks are chunks of code")

    # Send a follow up
    fill_in "Type a message…", with: "Give an example."
    stub_llm_response("3.times { puts 'hello' }")

    click_on "Send"

    # Trigger follow up job
    LLMChatResponseJob.perform_now(chat.id, "Give an example.")

    expect(chat.llm_messages.where(role: "assistant").last.content).to include("3.times")
  end
end
