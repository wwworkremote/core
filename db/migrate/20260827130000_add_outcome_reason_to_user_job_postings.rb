# frozen_string_literal: true

class AddOutcomeReasonToUserJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :user_job_postings, :outcome_reason, :text
  end
end
