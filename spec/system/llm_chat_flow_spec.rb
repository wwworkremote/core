# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Neural Dialogue UX", type: :system, js: true do
  include ActiveJob::TestHelper

  before do
    driven_by :cuprite
    LLM::Registry.sync
  end

  let!(:model) { create(:model, name: "Llama Local", model_id: "llama3.2:latest") }
  let(:user) { User.find_or_create_by!(email: "mike@just3ws.com") { |u| u.name = "Mike"; u.password = "password" } }

  it "allows a user to start a dialogue and receive a simulated response" do
    visit new_llm_chat_path
    
    select model.name, from: "llm_chat[model_id]"
    fill_in "llm_chat[prompt]", with: "Explain Ruby blocks."
    
    # Mock LLM for the initial prompt
    mock_output = "Ruby blocks are chunks of code."
    sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{mock_output.to_json}}}]}\n\ndata: [DONE]\n"
    stub_request(:post, "http://localhost:8080/v1/chat/completions")
      .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

    click_button "Establish Neural Link"
    expect(page).to have_text(/Neural link established/i)

    # Manually trigger the response job
    chat = LLMChat.last
    LLMChatResponseJob.perform_now(chat.id, "Explain Ruby blocks.")

    # Verify message was created in DB
    expect(chat.llm_messages.where(role: "assistant").last.content).to include("Ruby blocks are chunks of code")

    # Send a follow up
    fill_in "Describe your objective...", with: "Give an example."
    
    # Mock LLM for follow up
    mock_example = "3.times { puts 'hello' }"
    sse_example = "data: {\"choices\":[{\"delta\":{\"content\":#{mock_example.to_json}}}]}\n\ndata: [DONE]\n"
    stub_request(:post, "http://localhost:8080/v1/chat/completions")
      .to_return(status: 200, body: sse_example, headers: { "Content-Type" => "text/event-stream" })

    click_on "Send"
    
    # Trigger follow up job
    LLMChatResponseJob.perform_now(chat.id, "Give an example.")

    expect(chat.llm_messages.where(role: "assistant").last.content).to include("3.times")
  end
end
