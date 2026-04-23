# frozen_string_literal: true

class AssociateCompaniesToJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :job_postings, :company, index: false
    add_index :job_postings, :company_id, algorithm: :concurrently
    add_foreign_key :job_postings, :companies, validate: false
  end
end
