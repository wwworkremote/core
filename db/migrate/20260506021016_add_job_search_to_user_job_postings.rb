# frozen_string_literal: true

class AddJobSearchToUserJobPostings < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_reference :user_job_postings, :job_search, index: { algorithm: :concurrently }
  end
end
