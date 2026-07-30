# frozen_string_literal: true

class BackfillCompanyNameInJobPostings < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    return unless column_exists?(:job_postings, :company_name) && column_exists?(:job_postings, :company)

    backfill_company_name_column
  end

  def down
    return unless column_exists?(:job_postings, :company_name)

    execute <<~SQL.squish
      UPDATE job_postings SET company_name = NULL;
    SQL
  end

  private

  # Use raw SQL to bypass ActiveRecord column ignoring
  def backfill_company_name_column
    safety_assured do
      execute <<~SQL.squish
        UPDATE job_postings SET company_name = company WHERE company_name IS NULL;
      SQL
    end
  end
end
