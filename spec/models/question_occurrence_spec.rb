# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionOccurrence do
  it "keeps its evidence immutable after creation" do
    occurrence = create(:question_occurrence, raw_prompt: "Why us?")

    occurrence.raw_prompt = "reworded"

    expect(occurrence).not_to be_valid
    expect(occurrence.errors[:base].join).to include("immutable")
  end

  it "allows the archetype assignment to change without touching the wording" do
    occurrence = create(:question_occurrence)
    archetype = create(:question_archetype)

    occurrence.update!(question_archetype: archetype, archetype_confidence: 90, archetype_assigned_by: "mike")

    expect(occurrence.reload.question_archetype).to eq(archetype)
  end

  it "reads industry from the posting's AI category and outcome from the application" do
    posting = create(:job_posting, data: { "ai_category" => "fintech" })
    application = create(:user_job_posting, job_posting: posting, outcome: "rejected")
    occurrence = create(:question_occurrence, job_posting: posting, user_job_posting: application)

    expect(occurrence.industry).to eq("fintech")
    expect(occurrence.outcome).to eq("rejected")
  end
end
