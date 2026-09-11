# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
# Append-only human judgment on a ComparisonFinding (ADR 009). The latest
# applicable row wins for presentation; earlier rows are never overwritten.
class CreateFindingDispositions < ActiveRecord::Migration[8.1]
  def change
    create_table :finding_dispositions do |t|
      t.references :comparison_finding, null: false, foreign_key: true
      t.string :value, null: false
      t.text :rationale
      t.string :reviewer, null: false
      t.string :reviewer_label
      t.string :resume_persona_id
      t.bigint :source_disposition_id
      t.timestamps
    end
    add_index :finding_dispositions, %i[comparison_finding_id created_at]
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
