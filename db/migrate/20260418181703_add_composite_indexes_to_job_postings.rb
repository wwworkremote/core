# frozen_string_literal: true

class AddCompositeIndexesToJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :job_postings, %i[company published_at], order: { published_at: :desc }, algorithm: :concurrently
    add_index :job_postings, %i[source_id published_at], order: { published_at: :desc }, algorithm: :concurrently
  end
end
