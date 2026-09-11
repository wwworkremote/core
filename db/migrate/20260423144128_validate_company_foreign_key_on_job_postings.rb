# frozen_string_literal: true

class ValidateCompanyForeignKeyOnJobPostings < ActiveRecord::Migration[8.0]
  def change
    return unless foreign_key_exists?(:job_postings, :companies)
    # Only validate if it exists but is not validated
    # ActiveRecord doesn't have a direct 'validated?' check for FKs in migrations easily,
    # but validate_foreign_key is idempotent in its effect if already validated.
    validate_foreign_key :job_postings, :companies
  end
end
