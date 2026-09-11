# frozen_string_literal: true

# TASK-127 / wayfinder doc-7 (TASK-124): the automation-readiness loop that
# attaches to the Question Archetype (TASK-113).
# - archetype_readiness_assessments: append-only, FindingDisposition-style
#   (ADR 009). Latest applicable wins; a merge/split carries the prior one
#   forward as a suggestion, never silently as fact.
# - answer_proposal_verdicts: value-free. sha256 hashes + edit distance +
#   verdict, never the answer text (it already lives in the occurrence).
class CreateAutomationReadiness < ActiveRecord::Migration[8.1]
  def change
    create_readiness_assessments
    create_answer_proposal_verdicts
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create_readiness_assessments
    create_table :archetype_readiness_assessments do |t|
      t.references :question_archetype, null: false, foreign_key: true
      t.references :source_assessment, null: true,
                                       foreign_key: { to_table: :archetype_readiness_assessments }
      t.string :readiness_class, null: false
      t.text :rationale
      t.string :assessed_by, null: false
      t.datetime :assessed_at, null: false
      t.timestamps
    end
    add_index :archetype_readiness_assessments, %i[question_archetype_id assessed_at]
  end

  def create_answer_proposal_verdicts
    create_table :answer_proposal_verdicts do |t|
      t.references :question_archetype, null: false, foreign_key: true
      t.references :question_occurrence, null: true, foreign_key: true
      t.string :persona_id
      t.string :provider
      t.string :strategy_source, null: false
      t.string :proposed_text_sha256, null: false
      t.string :final_text_sha256
      t.integer :edit_distance
      t.string :verdict, null: false
      t.datetime :decided_at, null: false
      t.timestamps
    end
    add_index :answer_proposal_verdicts, %i[question_archetype_id strategy_source verdict]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
