# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: answer_proposal_verdicts
#
#  id                     :bigint           not null, primary key
#  decided_at             :datetime         not null
#  edit_distance          :integer
#  final_text_sha256      :string
#  proposed_text_sha256   :string           not null
#  provider               :string
#  strategy_source        :string           not null
#  verdict                :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  persona_id             :string
#  question_archetype_id  :bigint           not null
#  question_occurrence_id :bigint
#
# Indexes
#
#  idx_on_question_archetype_id_strategy_source_verdic_589ef49dee  (question_archetype_id,strategy_source,verdict)
#  index_answer_proposal_verdicts_on_question_archetype_id         (question_archetype_id)
#  index_answer_proposal_verdicts_on_question_occurrence_id        (question_occurrence_id)
#
# Foreign Keys
#
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#  fk_rails_...  (question_occurrence_id => question_occurrences.id)
#
RSpec.describe AnswerProposalVerdict do
  let(:archetype) { create(:question_archetype) }

  def sha = Digest::SHA256.hexdigest(SecureRandom.hex)

  it "accepts a value-free row" do
    verdict = archetype.answer_proposal_verdicts.new(strategy_source: "ai", verdict: "edited",
                                                     proposed_text_sha256: sha, final_text_sha256: sha,
                                                     edit_distance: 12)
    expect(verdict).to be_valid
  end

  it "rejects a hash column that carries raw text instead of a digest" do
    verdict = archetype.answer_proposal_verdicts.new(strategy_source: "ai", verdict: "accepted",
                                                     proposed_text_sha256: "Because the mission resonates")
    expect(verdict).not_to be_valid
    expect(verdict.errors[:proposed_text_sha256].join).to include("sha256")
  end

  it "lists archetypes with at least N verdicts" do
    5.times {
      archetype.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: "accepted", proposed_text_sha256: sha)
    }
    thin = create(:question_archetype)
    thin.answer_proposal_verdicts.create!(strategy_source: "ai", verdict: "accepted", proposed_text_sha256: sha)

    expect(described_class.with_enough_evidence(5)).to contain_exactly(archetype.id)
  end

  # TASK-127 AC#7 / Bounded Agency.
  describe "guardrail: readiness signals never reach a fill/submit path" do
    let(:readiness_reads) do
      /readiness_class|current_readiness|suggested_readiness|SuggestedReadiness|ArchetypeReadinessAssessment/
    end
    let(:writes_an_answer) do
      [/ApplicationFieldAnswer/, /answer_source:\s*["']submitted/, /update!\(.*answer_text/,
       /application_field_answers\.(create|new|find_or_initialize)/]
    end

    it "has no app file that both writes an answer and reads a readiness signal" do
      offenders = Rails.root.glob("app/**/*.rb").select do |path|
        source = path.read
        writes_an_answer.any? { |re| source.match?(re) } && source.match?(readiness_reads)
      end

      expect(offenders).to be_empty, "readiness reaches a fill/submit path in: #{offenders.join(', ')}"
    end
  end
end
