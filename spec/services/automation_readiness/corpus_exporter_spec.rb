# frozen_string_literal: true

require "rails_helper"

RSpec.describe AutomationReadiness::CorpusExporter do
  after { FileUtils.rm_rf(described_class::DIR) }

  def sha = Digest::SHA256.hexdigest(SecureRandom.hex)

  it "writes one git-ignored JSONL file per archetype, one line per verdict, value-free" do
    archetype = create(:question_archetype)
    archetype.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: "accepted", proposed_text_sha256: sha)
    archetype.answer_proposal_verdicts.create!(strategy_source: "template", verdict: "edited",
                                               proposed_text_sha256: sha, final_text_sha256: sha, edit_distance: 9)

    written = described_class.call

    expect(written).to eq(2)
    file = described_class::DIR.join("#{archetype.id}.jsonl")
    lines = file.readlines.map { |line| JSON.parse(line) }
    expect(lines.size).to eq(2)
    expect(lines.first.keys).to include("strategy_source", "verdict", "edit_distance", "proposed_sha256")
    expect(lines.first.keys).not_to include("proposed_text", "final_text", "answer_text")
  end
end
