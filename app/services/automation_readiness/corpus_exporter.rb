# frozen_string_literal: true

# TASK-127 AC#5: writes one git-ignored JSONL file per Question Archetype under
# data/datalake/corpus/ -- one line per AnswerProposalVerdict plus the strategy
# that produced the proposal. Value-free (the verdict rows already are).
# Consumed by a prompt-authoring session and by AutomationReadiness::Eval.
class AutomationReadiness::CorpusExporter
  DIR = Rails.root.join("data/datalake/corpus")

  def self.call = new.call

  def call
    FileUtils.mkdir_p(DIR)
    QuestionArchetype.active.find_each.sum { |archetype| export(archetype) }
  end

  private

  def export(archetype)
    verdicts = archetype.answer_proposal_verdicts.order(:decided_at).to_a
    return 0 if verdicts.empty?

    write_jsonl(archetype, verdicts)
    verdicts.size
  end

  def write_jsonl(archetype, verdicts)
    lines = verdicts.map { |verdict| line(archetype, verdict) }
    DIR.join("#{archetype.id}.jsonl").write("#{lines.join("\n")}\n")
  end

  def line(archetype, verdict)
    archetype_facts(archetype).merge(verdict_facts(verdict)).to_json
  end

  def archetype_facts(archetype)
    { archetype_id: archetype.id, canonical_prompt: archetype.canonical_prompt,
      question_kind: archetype.question_kind }
  end

  def verdict_facts(verdict)
    { strategy_source: verdict.strategy_source, verdict: verdict.verdict, edit_distance: verdict.edit_distance,
      persona_id: verdict.persona_id, provider: verdict.provider, decided_at: verdict.decided_at.iso8601,
      proposed_sha256: verdict.proposed_text_sha256, final_sha256: verdict.final_text_sha256 }
  end
end
