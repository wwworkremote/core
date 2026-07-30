# frozen_string_literal: true

class CreateInterviewLaboratory < ActiveRecord::Migration[8.0]
  def change
    create_interview_sessions_table
    create_interview_questions_table
    create_interview_tasks_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength
  def create_interview_sessions_table
    create_table :interview_sessions do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :session_type
      t.datetime :scheduled_at
      t.string :vibe
      t.text :notes
      t.text :feedback
      t.timestamps
    end
  end

  def create_interview_questions_table
    create_table :interview_questions do |t|
      t.references :interview_session, null: false, foreign_key: true
      t.text :question_text
      t.text :answer_text
      t.string :category
      t.timestamps
    end
  end

  def create_interview_tasks_table
    create_table :interview_tasks do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.datetime :due_at
      t.string :status
      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
