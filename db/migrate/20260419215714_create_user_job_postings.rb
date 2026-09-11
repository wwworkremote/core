# frozen_string_literal: true

class CreateUserJobPostings < ActiveRecord::Migration[8.0]
  def change
    create_user_job_postings_table
  end

  private

  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def create_user_job_postings_table
    create_table :user_job_postings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job_posting, null: false, foreign_key: true
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
