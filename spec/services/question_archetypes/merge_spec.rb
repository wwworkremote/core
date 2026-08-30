# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionArchetypes::Merge do
  it "moves occurrences and strategies to the target and tombstones the source" do
    source = create(:question_archetype, label: "why here")
    target = create(:question_archetype, label: "why us")
    occurrence = create(:question_occurrence, question_archetype: source, raw_prompt: "Why here?")
    create(:answer_strategy, question_archetype: source, answer_text: "Mission fit.", source: "authored")

    result = described_class.call(source: source, target: target)

    expect(result).to eq(target)
    expect(occurrence.reload.question_archetype).to eq(target)
    expect(occurrence.raw_prompt).to eq("Why here?")
    expect(target.answer_strategies.pluck(:answer_text)).to include("Mission fit.")
    expect(source.reload.merged_into).to eq(target)
  end

  it "skips a duplicate strategy already present on the target" do
    source = create(:question_archetype)
    target = create(:question_archetype)
    create(:answer_strategy, question_archetype: source, answer_text: "Same.", source: "authored")
    create(:answer_strategy, question_archetype: target, answer_text: "Same.", source: "authored")

    described_class.call(source: source, target: target)

    expect(target.answer_strategies.where(answer_text: "Same.").count).to eq(1)
  end

  it "refuses to merge an archetype into itself" do
    archetype = create(:question_archetype)
    expect { described_class.call(source: archetype, target: archetype) }.to raise_error(ArgumentError)
  end
end
