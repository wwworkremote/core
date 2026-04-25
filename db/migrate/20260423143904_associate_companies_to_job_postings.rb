# frozen_string_literal: true

class AssociateCompaniesToJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :job_postings, :company, index: false unless column_exists?(:job_postings, :company_id)

    add_index :job_postings, :company_id, algorithm: :concurrently unless index_exists?(:job_postings, :company_id)

    # Check if foreign key exists before adding
    return if foreign_key_exists?(:job_postings, :companies)
    add_foreign_key :job_postings, :companies, validate: false
  end
end
