# frozen_string_literal: true

# Lets existing code read/write JobPosting#company as either a plain
# string (legacy behavior, backed by the company_name column) or the
# real Company association, without shadowing the association itself.
module JobPosting::LegacyCompanyAccess
  extend ActiveSupport::Concern

  included do
    # Legacy string access, backed by company_name column
    alias_attribute :company_legacy, :company_name

    self.ignored_columns += ["company"]
  end

  # Allow existing code to use .company as a string without shadowing association
  def company=(val)
    if val.is_a?(String)
      self.company_name = val
    else
      super
    end
  end

  def company
    return super if super.is_a?(Company)

    company_name
  end

  def company_record
    return @company_record if defined?(@company_record)

    @company_record = Company.find_by(name: company)
  end
end
