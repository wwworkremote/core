# frozen_string_literal: true

# TASK-113 / ADR 008: the cross-application question knowledge graph.
# - question_occurrences: immutable per-application evidence (exact wording +
#   full provenance). Never flattened into a mutable canned-answer row.
# - question_archetypes: reviewable semantic clusters, mergeable/splittable.
# - answer_strategies: versioned, persona-aware, provenance-bearing answers
#   attached to an archetype -- advisory, never auto-filled.
class CreateQuestionKnowledgeGraph < ActiveRecord::Migration[8.1]
  def change
    create_archetypes
    create_occurrences
    create_answer_strategies
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def create_archetypes
    create_table :question_archetypes do |t|
      t.string :label, null: false
      t.string :canonical_prompt, null: false
      t.string :question_kind, null: false
      t.text :notes
      t.references :merged_into, null: true, foreign_key: { to_table: :question_archetypes }
      t.timestamps
    end
    add_index :question_archetypes, :question_kind
  end

  def create_occurrences
    create_table :question_occurrences do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :user_job_posting, null: true, foreign_key: true
      t.references :guided_session, null: true, foreign_key: true
      t.references :question_archetype, null: true, foreign_key: true
      t.string :provider
      t.string :persona_id
      t.string :page_step
      t.string :field_key
      t.text :raw_prompt, null: false
      t.string :normalized_prompt, null: false
      t.string :question_kind, null: false
      t.string :source_kind, null: false
      t.integer :archetype_confidence
      t.string :archetype_assigned_by
      t.string :datalake_extractor_version
      t.jsonb :context, null: false, default: {}
      t.datetime :observed_at, null: false
      t.timestamps
    end
    add_index :question_occurrences, :normalized_prompt
    add_index :question_occurrences,
              %i[user_job_posting_id field_key normalized_prompt source_kind],
              unique: true, name: "idx_question_occurrences_dedupe"
  end

  def create_answer_strategies
    create_table :answer_strategies do |t|
      t.references :question_archetype, null: false, foreign_key: true
      t.string :persona_id
      t.text :answer_text, null: false
      t.string :source, null: false
      t.string :sophistication, null: false
      t.integer :version, null: false, default: 1
      t.integer :confidence
      t.boolean :enabled, null: false, default: true
      t.jsonb :provenance, null: false, default: {}
      t.timestamps
    end
    add_index :answer_strategies, %i[question_archetype_id persona_id source]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
