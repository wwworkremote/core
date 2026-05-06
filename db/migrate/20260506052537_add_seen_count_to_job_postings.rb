# frozen_string_literal: true

class AddSeenCountToJobPostings < ActiveRecord::Migration[7.2]
  def change
    add_column :job_postings, :seen_count, :integer, default: 1, null: false
  end
end
