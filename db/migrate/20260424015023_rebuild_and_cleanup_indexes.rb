# frozen_string_literal: true

class RebuildAndCleanupIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    rebuild_invalid_indexes
    remove_redundant_indexes
    add_missing_indexes
  end

  private

  # These indexes were previously created without CONCURRENTLY and ended up
  # invalid -- drop (by name, with the column so the removal stays
  # reversible) and recreate concurrently.
  def rebuild_invalid_indexes
    rebuild_companies_indexes
    rebuild_job_postings_indexes
  end

  def rebuild_companies_indexes
    remove_index :companies, name: "index_companies_on_name", column: :name, if_exists: true
    add_index :companies, :name, unique: true, algorithm: :concurrently
  end

  def rebuild_job_postings_indexes
    rebuild_job_postings_single_column_indexes
    rebuild_job_postings_composite_index
  end

  def rebuild_job_postings_single_column_indexes
    remove_index :job_postings, name: "index_job_postings_on_company_id", column: :company_id, if_exists: true
    add_index :job_postings, :company_id, algorithm: :concurrently

    remove_index :job_postings, name: "index_job_postings_on_company_name", column: :company_name, if_exists: true
    add_index :job_postings, :company_name, algorithm: :concurrently
  end

  def rebuild_job_postings_composite_index
    remove_index :job_postings, name: "index_job_postings_on_company_name_and_published_at",
                                column: %i[company_name published_at], if_exists: true
    add_index :job_postings, %i[company_name published_at], order: { published_at: :desc }, algorithm: :concurrently
  end

  def remove_redundant_indexes
    # Covered by index_job_postings_on_company_and_published_at
    remove_index :job_postings, :company, algorithm: :concurrently, if_exists: true
    # Covered by index_job_postings_on_source_id_and_published_at
    remove_index :job_postings, :source_id, algorithm: :concurrently, if_exists: true
  end

  def add_missing_indexes
    # Signature is frequently used for lookups and uniqueness checks
    unless index_exists?(:job_postings, :signature)
      add_index :job_postings, :signature, algorithm: :concurrently, unique: true
    end

    # Resolve slow queries on JobBoards::Document state filtering
    return if index_exists?(:job_boards_documents, :aasm_state)

    add_index :job_boards_documents, :aasm_state, algorithm: :concurrently
  end
end
