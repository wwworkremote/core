# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionArchetypes::Split do
  it "moves the named occurrences to a fresh archetype, keeping the rest and all wording" do
    archetype = create(:question_archetype, label: "authorization")
    stay = create(:question_occurrence, question_archetype: archetype,
                                        raw_prompt: "Are you authorized to work in the US?")
    move = create(:question_occurrence, question_archetype: archetype, raw_prompt: "Do you require sponsorship?",
                                        normalized_prompt: "do you require sponsorship", question_kind: "eligibility")

    new_archetype = described_class.call(archetype: archetype, occurrence_ids: [move.id], label: "sponsorship")

    expect(new_archetype.label).to eq("sponsorship")
    expect(move.reload.question_archetype).to eq(new_archetype)
    expect(move.raw_prompt).to eq("Do you require sponsorship?")
    expect(stay.reload.question_archetype).to eq(archetype)
  end

  it "carries the parent's readiness onto the split-off archetype as a suggestion (TASK-127)" do
    archetype = create(:question_archetype)
    keep = create(:question_occurrence, question_archetype: archetype)
    move = create(:question_occurrence, question_archetype: archetype, raw_prompt: "Other?")
    archetype.readiness_assessments.create!(readiness_class: "generatable", assessed_by: "mike")

    new_archetype = described_class.call(archetype: archetype, occurrence_ids: [move.id])

    expect(new_archetype.current_readiness).to have_attributes(readiness_class: "generatable")
    expect(new_archetype.current_readiness).to be_carried_forward
    expect(keep.reload.question_archetype).to eq(archetype)
  end

  it "refuses to split off nothing or everything" do
    archetype = create(:question_archetype)
    only = create(:question_occurrence, question_archetype: archetype)

    expect { described_class.call(archetype: archetype, occurrence_ids: []) }.to raise_error(ArgumentError)
    expect { described_class.call(archetype: archetype, occurrence_ids: [only.id]) }.to raise_error(ArgumentError)
  end
end
