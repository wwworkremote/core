# frozen_string_literal: true

# Resolves (or creates) the Company for a mapped JobPosting and marks it
# ignored if that company has ingestion disabled -- split out of
# JobBoards::Syncer to keep the sync-flow class itself under
# Metrics/ClassLength.
class JobBoards::Syncer::CompanyResolver
  def self.call(job_posting)
    new(job_posting).call
  end

  def initialize(job_posting)
    @job_posting = job_posting
  end

  def call
    return if @job_posting.company_name.blank?

    company = find_or_create_company
    @job_posting.company_id = company.id
    @job_posting.ignore unless company.ingestion_enabled?
  end

  private

  def find_or_create_company
    name = @job_posting.company_name
    Company.find_or_create_by!(name: name) { |c| c.slug = name.parameterize }
  end
end
