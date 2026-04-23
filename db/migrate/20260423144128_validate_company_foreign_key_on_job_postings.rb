# frozen_string_literal: true

class ValidateCompanyForeignKeyOnJobPostings < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :job_postings, :companies
  end
end
