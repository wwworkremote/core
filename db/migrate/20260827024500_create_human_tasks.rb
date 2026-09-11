# frozen_string_literal: true

class CreateHumanTasks < ActiveRecord::Migration[8.1]
  # rubocop:disable-next Metrics/AbcSize, Metrics/MethodLength -- one cohesive
  # table definition; splitting it would obscure the schema, not simplify it.
  def change
    create_table :human_tasks do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # persona_review, question_answer, resume_review, submit_approval --
      # BPMN "User Task" vocabulary: work only a human can resolve, proposed
      # by an automated "Service Task" (see Pipeline::PersonaRecommender).
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"

      # Whatever the automated step proposed (a suggested persona_id +
      # rationale, a drafted answer) -- shown to the human for approve/edit/
      # reject, never acted on directly.
      t.jsonb :payload, null: false, default: {}
      t.string :proposed_by, null: false, default: "ai"

      t.text :resolution_note
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :human_tasks, %i[job_posting_id kind status]
    add_index :human_tasks, :status
  end
end
