# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionOccurrences::Record do
  let(:application) { create(:user_job_posting) }

  def observation(**overrides)
    create(:application_field_observation, { user_job_posting: application, field_key: "why_us",
                                             field_label: "Why do you want to work here?",
                                             normalized_prompt: "why do you want to work here",
                                             question_kind: "motivation" }.merge(overrides))
  end

  it "records an observed question and auto-assigns an archetype by exact prompt" do
    occurrence = described_class.call(observation)

    expect(occurrence).to have_attributes(source_kind: "observed", raw_prompt: "Why do you want to work here?",
                                          archetype_confidence: 100, archetype_assigned_by: "auto:exact_prompt")
    expect(occurrence.question_archetype.canonical_prompt).to eq("why do you want to work here")
  end

  it "aggregates duplicate observations across applications onto one archetype without losing provenance" do
    first = described_class.call(observation)
    other_app = create(:user_job_posting)
    second = described_class.call(observation(user_job_posting: other_app))

    expect(second.question_archetype).to eq(first.question_archetype)
    expect(first.user_job_posting).not_to eq(second.user_job_posting)
    expect(QuestionOccurrence.count).to eq(2)
  end

  it "is idempotent -- re-recording the same observation makes no new row" do
    obs = observation
    described_class.call(obs)

    expect { described_class.call(obs) }.not_to change(QuestionOccurrence, :count)
  end

  it "skips pure identity/contact fields" do
    expect(described_class.call(observation(question_kind: "identity"))).to be_nil
    expect(QuestionOccurrence.count).to eq(0)
  end

  it "records a manual ApplicationQuestion as an occurrence" do
    question = create(:job_posting).application_questions.create!(user: application.user,
                                                                  question_text: "What is your greatest weakness?")

    occurrence = QuestionOccurrence.find_by(source_kind: "manual_question")
    expect(occurrence.raw_prompt).to eq("What is your greatest weakness?")
    expect(occurrence.question_archetype).to be_present
    expect(question.reload).to be_persisted
  end
end
