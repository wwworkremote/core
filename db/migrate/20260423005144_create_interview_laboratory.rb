class CreateInterviewLaboratory < ActiveRecord::Migration[8.0]
  def change
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

    create_table :interview_questions do |t|
      t.references :interview_session, null: false, foreign_key: true
      t.text :question_text
      t.text :answer_text
      t.string :category
      t.timestamps
    end

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
end
