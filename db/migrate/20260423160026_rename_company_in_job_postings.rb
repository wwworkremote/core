# frozen_string_literal: true

class RenameCompanyInJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Step 1: Create a new column
    add_column :job_postings, :company_name, :string
    
    # Step 2: Add indexes concurrently
    add_index :job_postings, :company_name, algorithm: :concurrently
    add_index :job_postings, [:company_name, :published_at], order: { published_at: :desc }, algorithm: :concurrently
  end
end
