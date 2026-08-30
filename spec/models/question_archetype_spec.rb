# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionArchetype do
  it "reports its distinct wording variants, most common first" do
    archetype = create(:question_archetype)
    create_list(:question_occurrence, 2, question_archetype: archetype, raw_prompt: "Why do you want this role?")
    create(:question_occurrence, question_archetype: archetype, raw_prompt: "What draws you here?")

    expect(archetype.wording_variants.keys.first).to eq("Why do you want this role?")
  end

  it "separates active archetypes from merged tombstones" do
    live = create(:question_archetype)
    tombstone = create(:question_archetype, merged_into: live)

    expect(described_class.active).to contain_exactly(live)
    expect(described_class.merged).to contain_exactly(tombstone)
    expect(tombstone).to be_merged
  end
end
