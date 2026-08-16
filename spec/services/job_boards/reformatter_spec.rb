# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::Reformatter do
  let(:job_posting) { create(:job_posting, body: "we need a rubyist. duties: build stuff. reqs: 5yrs exp", data: {}) }
  let(:reformatter) { described_class.new(job_posting) }
  let(:model_id) { LLM::Registry.default_model_id }
  # find_or_create, not create: rails_helper's before(:suite) already syncs
  # LLM::Registry's models once for the whole run, outside any per-example
  # transaction -- a bare create collides with that row's unique index.
  let!(:model) do
    Model.find_or_create_by!(model_id: model_id, provider: "ollama") { |m| m.name = model_id }
  end

  before do
    RubyLLM.config.default_model = model_id
    allow(LLM::Registry).to receive(:default_model).and_return(model)
  end

  def stub_llm_response(body)
    stub_request(:post, "http://localhost:11500/v1/chat/completions")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "text/event-stream" })
  end

  def sse_body(content)
    "data: {\"choices\":[{\"delta\":{\"content\":#{content.inspect}}}]}\n\ndata: [DONE]\n"
  end

  describe "#call" do
    it "stores the reformatted output in data[\"formatted_body\"] without touching body" do
      formatted = "## Role\n\n- Build stuff\n\n## Requirements\n\n- 5 years experience"
      stub_llm_response(sse_body(formatted))

      reformatter.call

      job_posting.reload
      expect(job_posting.data["formatted_body"]).to eq(formatted)
      expect(job_posting.body).to eq("we need a rubyist. duties: build stuff. reqs: 5yrs exp")
    end

    it "clears the reformatting pending flag on success" do
      job_posting.update!(data: { "reformatting" => true })
      stub_llm_response(sse_body("cleaned up text"))

      reformatter.call

      expect(job_posting.reload.data["reformatting"]).to be false
    end

    it "clears the reformatting pending flag even when the LLM call fails" do
      job_posting.update!(data: { "reformatting" => true })
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")
      allow(Rails.logger).to receive(:error)

      reformatter.call

      expect(job_posting.reload.data["reformatting"]).to be false
      expect(job_posting.data["formatted_body"]).to be_nil
    end

    it "logs and does not raise when the LLM call fails" do
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")
      allow(Rails.logger).to receive(:error)

      expect { reformatter.call }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(include("Reformatter"))
    end

    it "does not overwrite formatted_body when the LLM returns a blank response" do
      job_posting.update!(data: { "formatted_body" => "existing reformatted text" })
      stub_llm_response(sse_body(""))

      reformatter.call

      expect(job_posting.reload.data["formatted_body"]).to eq("existing reformatted text")
    end
  end
end
