# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: archetype_readiness_assessments
#
#  id                    :bigint           not null, primary key
#  assessed_at           :datetime         not null
#  assessed_by           :string           not null
#  rationale             :text
#  readiness_class       :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  question_archetype_id :bigint           not null
#  source_assessment_id  :bigint
#
# Indexes
#
#  idx_on_question_archetype_id_assessed_at_f44acfd079             (question_archetype_id,assessed_at)
#  index_archetype_readiness_assessments_on_question_archetype_id  (question_archetype_id)
#  index_archetype_readiness_assessments_on_source_assessment_id   (source_assessment_id)
#
# Foreign Keys
#
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#  fk_rails_...  (source_assessment_id => archetype_readiness_assessments.id)
#
RSpec.describe ArchetypeReadinessAssessment do
  let(:archetype) { create(:question_archetype) }

  it "is append-only -- the latest applicable row wins and history is never overwritten" do
    old = archetype.readiness_assessments.create!(readiness_class: "needs_human", assessed_by: "mike",
                                                  assessed_at: 2.days.ago)
    current = archetype.readiness_assessments.create!(readiness_class: "generatable", assessed_by: "mike")

    expect(described_class.current_for(archetype)).to eq(current)
    expect { old.update!(readiness_class: "deterministic") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "flags a carried-forward assessment as advisory" do
    carried = archetype.readiness_assessments.create!(readiness_class: "deterministic",
                                                      assessed_by: described_class::CARRIED_FORWARD_BY)

    expect(carried).to be_carried_forward
  end
end
