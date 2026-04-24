# frozen_string_literal: true

class AssociateCompaniesToJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    unless column_exists?(:job_postings, :company_id)
      add_reference :job_postings, :company, index: false
    end

    unless index_exists?(:job_postings, :company_id)
      add_index :job_postings, :company_id, algorithm: :concurrently
    end

    # Check if foreign key exists before adding
    unless foreign_key_exists?(:job_postings, :companies)
      add_foreign_key :job_postings, :companies, validate: false
    end
  end
end
