# frozen_string_literal: true

class RebuildAndCleanupIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # 1. Rebuild Invalid Indexes
    # Companies
    remove_index :companies, name: 'index_companies_on_name', if_exists: true
    add_index :companies, :name, unique: true, algorithm: :concurrently

    # JobPostings
    remove_index :job_postings, name: 'index_job_postings_on_company_id', if_exists: true
    add_index :job_postings, :company_id, algorithm: :concurrently

    remove_index :job_postings, name: 'index_job_postings_on_company_name', if_exists: true
    add_index :job_postings, :company_name, algorithm: :concurrently

    remove_index :job_postings, name: 'index_job_postings_on_company_name_and_published_at', if_exists: true
    add_index :job_postings, [:company_name, :published_at], order: { published_at: :desc }, algorithm: :concurrently

    # 2. Remove Redundant Indexes
    # Covered by index_job_postings_on_company_and_published_at
    remove_index :job_postings, :company, algorithm: :concurrently, if_exists: true
    # Covered by index_job_postings_on_source_id_and_published_at
    remove_index :job_postings, :source_id, algorithm: :concurrently, if_exists: true

    # 3. Add Suggested/Missing Indexes
    # Signature is frequently used for lookups and uniqueness checks
    add_index :job_postings, :signature, algorithm: :concurrently, unique: true unless index_exists?(:job_postings, :signature)

    # Resolve slow queries on JobBoards::Document state filtering
    add_index :job_boards_documents, :aasm_state, algorithm: :concurrently unless index_exists?(:job_boards_documents, :aasm_state)
  end
end
