# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: question_archetypes
#
#  id               :bigint           not null, primary key
#  canonical_prompt :string           not null
#  label            :string           not null
#  notes            :text
#  question_kind    :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  merged_into_id   :bigint
#
# Indexes
#
#  index_question_archetypes_on_merged_into_id  (merged_into_id)
#  index_question_archetypes_on_question_kind   (question_kind)
#
# Foreign Keys
#
#  fk_rails_...  (merged_into_id => question_archetypes.id)
#
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
