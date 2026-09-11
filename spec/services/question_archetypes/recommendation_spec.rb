# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionArchetypes::Recommendation do
  it "recommends needs_human with low confidence when evidence is thin" do
    archetype = create(:question_archetype, question_kind: "eligibility")
    create(:question_occurrence, question_archetype: archetype)

    result = described_class.call(archetype)

    expect(result.handling).to eq("needs_human")
    expect(result.confidence).to be <= 30
    expect(result.rationale).to match(/not enough/i)
  end

  it "recommends deterministic for an eligibility question seen across companies" do
    archetype = create(:question_archetype, question_kind: "eligibility")
    3.times { create(:question_occurrence, question_archetype: archetype, job_posting: create(:job_posting)) }

    result = described_class.call(archetype)

    expect(result.handling).to eq("deterministic")
    expect(result.confidence).to be > 30
  end

  it "recommends needs_human for a motivation question" do
    archetype = create(:question_archetype, question_kind: "motivation")
    3.times { create(:question_occurrence, question_archetype: archetype, job_posting: create(:job_posting)) }

    expect(described_class.call(archetype).handling).to eq("needs_human")
  end
end
