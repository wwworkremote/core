# frozen_string_literal: true

class AddStrategyToUserJobPostings < ActiveRecord::Migration[8.1]
  def change
    add_column :user_job_postings, :strategy, :jsonb, null: false, default: {}
  end
end
