# frozen_string_literal: true

require "rails_helper"

# TASK-113 AC#7: the repeatable proof that duplicate observations aggregate
# without losing per-application provenance.
RSpec.describe QuestionGraph::SandboxWalkthrough do
  it "aggregates the same questions across two applications onto shared archetypes, provenance intact" do
    report = described_class.call

    expect(report[:archetypes]).to eq(2)
    expect(report[:occurrences]).to eq([2, 2])
    expect(report[:provenance_intact]).to be(true)
  end

  it "is idempotent -- a second run adds no rows" do
    described_class.call

    expect { described_class.call }.not_to change(QuestionOccurrence, :count)
  end
end
