# frozen_string_literal: true

require "rails_helper"

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
