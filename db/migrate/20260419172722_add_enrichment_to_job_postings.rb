# frozen_string_literal: true

class AddEnrichmentToJobPostings < ActiveRecord::Migration[8.0]
  def change
    change_table :job_postings, bulk: true do |t|
      t.datetime :enriched_at
      t.string :crawl_status
    end
  end
end
