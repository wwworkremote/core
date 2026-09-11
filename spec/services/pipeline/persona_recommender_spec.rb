# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pipeline::PersonaRecommender do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting, title: "Founding Engineer", body: "Build 0-to-1 AI systems.") }
  let(:llm_output) do
    "PERSONA_ID: founding_staff_fullstack\nCONFIDENCE: 90\n" \
      "RATIONALE: Greenfield AI product work matches this persona directly."
  end
  let(:persona_source) do
    {
      "archetypes" => {
        "founding_staff_fullstack" => {
          "short_label" => "Founding Staff", "title" => "Founding Staff Engineer",
          "target_tier" => "early-stage", "summary" => "Summary", "core_skills" => [],
          "featured_positions" => [], "additional_experience" => [], "selected_projects" => []
        }
      }, "positions" => {}
    }
  end

  before do
    allow(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: llm_output })
    allow(Resume::Source).to receive(:new).and_return(instance_double(Resume::Source, to_h: persona_source))
  end

  it "creates a pending persona_review HumanTask with the parsed proposal" do
    task = described_class.call(job_posting: job_posting, user: user)

    expect(task).to be_pending
    expect(task.kind).to eq("persona_review")
    expect(task.proposed_by).to eq("ai")
    expect(task.payload).to include("persona_id" => "founding_staff_fullstack", "confidence" => 90)
  end

  it "never applies the persona itself -- only proposes it" do
    described_class.call(job_posting: job_posting, user: user)

    expect(user.user_job_postings.find_by(job_posting: job_posting)&.resume_persona_id).to be_nil
  end

  it "is idempotent -- returns the existing open task instead of creating a duplicate" do
    first = described_class.call(job_posting: job_posting, user: user)
    second = described_class.call(job_posting: job_posting, user: user)

    expect(second).to eq(first)
    expect(HumanTask.where(job_posting: job_posting, kind: "persona_review").count).to eq(1)
  end

  it "creates a new task once the prior one is resolved" do
    first = described_class.call(job_posting: job_posting, user: user)
    first.approve!

    second = described_class.call(job_posting: job_posting, user: user)

    expect(second).not_to eq(first)
  end
end
