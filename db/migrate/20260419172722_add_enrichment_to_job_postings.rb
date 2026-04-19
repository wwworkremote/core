class AddEnrichmentToJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :job_postings, :enriched_at, :datetime
    add_column :job_postings, :crawl_status, :string
  end
end
