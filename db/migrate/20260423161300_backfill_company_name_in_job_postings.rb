# frozen_string_literal: true

class BackfillCompanyNameInJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    return unless column_exists?(:job_postings, :company_name) && column_exists?(:job_postings, :company)

    # Use raw SQL to bypass ActiveRecord column ignoring
    safety_assured do
      execute <<-SQL
        UPDATE job_postings SET company_name = company WHERE company_name IS NULL;
      SQL
    end
  end

  def down
    return unless column_exists?(:job_postings, :company_name)

    execute <<-SQL
      UPDATE job_postings SET company_name = NULL;
    SQL
  end
end
