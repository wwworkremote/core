# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionGraph::Backfill do
  def observe(application)
    create(:application_field_observation, user_job_posting: application, field_key: "why_us",
                                           field_label: "Why us?", normalized_prompt: "why us",
                                           question_kind: "motivation")
  end

  it "backfills occurrences from existing observations and is re-runnable" do
    observe(create(:user_job_posting))

    first = described_class.call
    expect(first[:occurrences]).to eq(1)
    expect { described_class.call }.not_to change(QuestionOccurrence, :count)
  end

  it "seeds an authored answer strategy from a matching ApplicationAnswerTemplate" do
    application = create(:user_job_posting)
    observe(application)
    ApplicationAnswerTemplate.create!(user: application.user, question_kind: "motivation", prompt: "Why us?",
                                      normalized_prompt: "why us", answer: "Because the mission.", source: "manual")

    described_class.call

    archetype = QuestionArchetype.find_by(canonical_prompt: "why us")
    expect(archetype.answer_strategies.pluck(:answer_text, :source))
      .to contain_exactly(["Because the mission.", "authored"])
  end
end
