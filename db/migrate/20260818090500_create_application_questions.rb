# frozen_string_literal: true

class CreateApplicationQuestions < ActiveRecord::Migration[8.1]
  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def change
    create_table :application_questions do |t|
      t.references :job_posting, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :question_text
      t.text :answer_text
      t.string :answer_source
      t.timestamps
    end
  end
end
