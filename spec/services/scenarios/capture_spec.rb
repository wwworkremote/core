# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::Capture do
  def har_with(entries)
    { "log" => { "entries" => entries } }.to_json
  end

  def entry(url:, body: nil, base64: false)
    { "request" => { "url" => url }, "response" => { "content" => content_for(body, base64) } }
  end

  def content_for(body, base64)
    return {} unless body

    { "text" => base64 ? Base64.encode64(body) : body, "encoding" => base64 ? "base64" : nil }
  end

  describe "#call" do
    it "creates a Scenario and a ScenarioSignature from a job id found in a HAR request URL" do
      source = har_with([entry(url: "https://www.linkedin.com/jobs/view/4123456789/")])

      scenario = described_class.call(source, provider: "linkedin")

      expect(scenario).to be_persisted
      expect(scenario.provider).to eq("linkedin")
      expect(scenario.scenario_signatures.pluck(:kind, :value)).to contain_exactly(%w[job_id 4123456789])
    end

    it "extracts the same job id from a saved DOM capture, no HAR wrapper needed" do
      source = <<~HTML
        <html><body><a href="https://www.linkedin.com/jobs/view/4123456789/">Staff Engineer</a></body></html>
      HTML

      scenario = described_class.call(source, provider: "linkedin")

      expect(scenario.scenario_signatures.pluck(:kind)).to contain_exactly("job_id")
    end

    it "decodes a base64-encoded HAR response body to find a signature (Chrome mixes both within one capture)" do
      body = { "job_post_id" => 555_444, "ats_application_id" => "abc-123" }.to_json
      source = har_with([entry(url: "https://job-boards.greenhouse.io/acme/applications.json", body: body,
                               base64: true)])

      scenario = described_class.call(source, provider: "greenhouse")

      expect(scenario.scenario_signatures.pluck(:kind, :value)).to contain_exactly(
        %w[job_post_id 555444], %w[ats_application_id abc-123]
      )
    end

    it "extracts Greenhouse signatures from the sandbox DOM" do
      source = '<form data-job-post-id="sandbox-job"><div data-ats-application-id="sandbox-application"></div></form>'

      scenario = described_class.call(source, provider: "greenhouse")

      expect(scenario.scenario_signatures.pluck(:kind, :value)).to contain_exactly(
        %w[job_post_id sandbox-job], %w[ats_application_id sandbox-application]
      )
    end

    it "extracts nothing for a provider with no configured patterns, but still creates the Scenario" do
      scenario = described_class.call("irrelevant text", provider: "unknown_board")

      expect(scenario).to be_persisted
      expect(scenario.scenario_signatures).to be_empty
    end

    it "captures resume_persona_id on the Scenario when a real persona was in play" do
      source = har_with([entry(url: "https://www.linkedin.com/jobs/view/111/")])

      scenario = described_class.call(source, provider: "linkedin", scenario_attrs: { resume_persona_id: "staff-eng" })

      expect(scenario.resume_persona_id).to eq("staff-eng")
    end

    it "leaves resume_persona_id nil for a verification-only capture with no real persona in play" do
      source = har_with([entry(url: "https://www.linkedin.com/jobs/view/111/")])

      scenario = described_class.call(source, provider: "linkedin")

      expect(scenario.resume_persona_id).to be_nil
    end

    it "is idempotent -- re-running the same source against the same Scenario does not duplicate signatures" do
      source = har_with([entry(url: "https://www.linkedin.com/jobs/view/222/")])
      scenario = described_class.call(source, provider: "linkedin")

      expect do
        described_class.call(source, provider: "linkedin", scenario: scenario)
      end.not_to change(ScenarioSignature, :count)
      expect(scenario.scenario_signatures.count).to eq(1)
    end

    it "records a changed value under the same kind as a new row, not an overwrite (append-only correction)" do
      first_source = har_with([entry(url: "https://www.linkedin.com/jobs/view/111/")])
      scenario = described_class.call(first_source, provider: "linkedin")

      second_source = har_with([entry(url: "https://www.linkedin.com/jobs/view/222/")])
      expect do
        described_class.call(second_source, provider: "linkedin", scenario: scenario)
      end.to change(ScenarioSignature, :count).by(1)
      expect(scenario.scenario_signatures.pluck(:value)).to contain_exactly("111", "222")
    end

    it "gives Scenarios::HandshakeCheck correct, real results against a Scenario built this way" do
      source = har_with([entry(url: "https://www.linkedin.com/jobs/view/999/")])

      scenario = described_class.call(source, provider: "linkedin")

      result = Scenarios::HandshakeCheck.call(scenario)
      expect(result).to contain_exactly(
        { kind: "job_id", requirement: :required, present: true, status: "required-and-present" }
      )
    end

    it "leaves Scenarios::HandshakeCheck reporting required-and-missing when the capture never found the signature" do
      scenario = described_class.call("no ids in here", provider: "linkedin")

      result = Scenarios::HandshakeCheck.call(scenario)
      expect(result).to contain_exactly(
        { kind: "job_id", requirement: :required, present: false, status: "required-and-missing" }
      )
    end
  end
end
