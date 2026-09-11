# frozen_string_literal: true

class AddMatchAnalysisToUserJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :user_job_postings, :match_analysis, :text
  end
end
