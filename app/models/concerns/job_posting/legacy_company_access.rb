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

  # #company already returns the real Company when company_id is resolved
  # (see above) -- Company.find_by(name: company) unconditionally would
  # pass that Company object as the :name lookup value in that case and
  # silently return nil, not the record already in hand.
  def company_record
    return @company_record if defined?(@company_record)

    resolved = company
    @company_record = resolved.is_a?(Company) ? resolved : Company.find_by(name: resolved)
  end
end
