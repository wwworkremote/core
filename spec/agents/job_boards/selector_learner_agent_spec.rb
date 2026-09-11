# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::SelectorLearnerAgent do
  let(:model_id) { "llama3.2:latest" }
  let!(:model) { create(:model, model_id: model_id, provider: "ollama") }
  # RubyLLM::Agent#initialize eagerly builds a real RubyLLM.chat (resolving
  # RubyLLM's own gem-level default model, unrelated to this app's Model/
  # LLM::Registry system) unless a chat: is passed in. LLM::Orchestrator
  # never touches @agent.chat -- it only calls render_instructions and
  # builds its own LLMChat -- so a bare object safely no-ops through
  # RubyLLM::Agent's class-level configuration hooks (none of which this
  # agent uses; instructions/schema are plain instance methods instead).
  let(:agent) { described_class.new(chat: Object.new) }

  before do
    allow(LLM::Registry).to receive(:default_model).and_return(model)
  end


  describe "#call" do
    it "returns the LLM's proposed selector when the call succeeds" do
      sse_body = <<~SSE
        data: {"choices":[{"delta":{"content":"{\\"selector\\": \\"h1#job-title\\"}"}}]}

        data: [DONE]
      SSE
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      element = "<h1 id=\"job-title\">Staff Engineer</h1>"
      selector = agent.call(
        field_name: "title", candidate_selector: "h1.top-card-layout__title:nth-of-type(1)",
        element_html: element, parent_html: "<div>#{element}</div>"
      )

      expect(selector).to eq("h1#job-title")
    end

    it "falls back to the candidate selector when the LLM call fails" do
      stub_request(:post, %r{localhost:11500/v1/chat/completions})
        .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      candidate = "h1.top-card-layout__title:nth-of-type(1)"
      selector = agent.call(
        field_name: "title", candidate_selector: candidate,
        element_html: "<h1>Staff Engineer</h1>", parent_html: "<div><h1>Staff Engineer</h1></div>"
      )

      expect(selector).to eq(candidate)
    end

    it "falls back to the candidate selector when the LLM returns unparseable output" do
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: "", headers: {})

      candidate = "h1.top-card-layout__title:nth-of-type(1)"
      selector = agent.call(
        field_name: "title", candidate_selector: candidate,
        element_html: "<h1>Staff Engineer</h1>", parent_html: "<div><h1>Staff Engineer</h1></div>"
      )

      expect(selector).to eq(candidate)
    end
  end
end
