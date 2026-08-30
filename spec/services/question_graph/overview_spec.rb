# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuestionGraph::Overview do
  it "ranks archetypes by occurrence count with per-dimension spread" do
    hot = create(:question_archetype, label: "why us")
    cold = create(:question_archetype, label: "start date")
    create(:question_occurrence, question_archetype: hot, provider: "greenhouse", job_posting: create(:job_posting))
    create(:question_occurrence, question_archetype: hot, provider: "lever", job_posting: create(:job_posting))
    create(:question_occurrence, question_archetype: cold)

    result = described_class.call

    expect(result[:rows].map(&:archetype)).to eq([hot, cold])
    top = result[:rows].first
    expect(top).to have_attributes(occurrences: 2, companies: 2, providers: 2, strategies: 0)
  end

  it "lists recurring archetypes with no answer strategy as coverage gaps" do
    gap = create(:question_archetype, label: "weakness")
    create_list(:question_occurrence, 2, question_archetype: gap)
    covered = create(:question_archetype, label: "covered")
    create_list(:question_occurrence, 2, question_archetype: covered)
    create(:answer_strategy, question_archetype: covered)

    expect(described_class.call[:coverage_gaps]).to contain_exactly(gap)
  end
end
