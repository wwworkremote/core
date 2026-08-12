# frozen_string_literal: true

# Promotes a captured Lead into a real JobPosting: resolves (or creates,
# once the user has confirmed via the extension's review panel) the
# Company, resolves/creates the board-level Source + Origin the same way
# the scraper pipeline does (JobBoards::Syncer#resolve_dashboard_source),
# finds-or-creates the JobPosting, links the Lead to all three, and
# enqueues the same downstream analysis + AI pipeline a scraped posting
# would get.
class Leads::CaptureService
  def self.call(...)
    new(...).call
  end

  def initialize(lead:, params:, user:)
    @lead = lead
    @params = params
    @user = user
  end

  def call
    perform
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.message }
  end

  private

  def perform
    company, source, job_posting = resolve_records
    link_lead(job_posting, company, source)
    enqueue_pipeline(job_posting)
    { success: true, job_posting: job_posting }
  end

  def resolve_records
    company = resolve_company
    source = resolve_source
    [company, source, resolve_job_posting(company, source)]
  end

  def resolve_company
    return Company.find_by(id: @params[:company_id]) if @params[:company_id].present?

    name = @params.dig(:company, :name)
    name.present? ? find_or_create_company(name) : nil
  end

  def find_or_create_company(name)
    Company.find_or_create_by!(name: name) { |c| c.slug = name.parameterize; c.status = "none" }
  end

  def resolve_source
    origin = Origin.find_or_create_by!(name: @lead.provider)
    Source.find_or_create_by!(signature: "#{@lead.provider}-default") do |s|
      s.origin = origin
      s.name = @lead.provider
    end
  end

  def resolve_job_posting(company, source)
    job = find_or_initialize_job_posting
    apply_job_posting_attributes(job, company, source)
    job.save!
    job
  end

  def find_or_initialize_job_posting
    target_url = @params[:target_url]
    signature = Digest::SHA256.hexdigest(target_url.to_s)
    existing = JobPosting.find_by(signature: signature)
    return reusable_job_posting(existing, target_url, signature) if existing.nil? || existing.id == @lead.job_posting_id

    unowned_collision_job_posting(target_url)
  end

  def reusable_job_posting(existing, target_url, signature)
    job = existing || JobPosting.new(signature: signature)
    job.target_url = target_url
    job
  end

  # Signature collision with a posting this lead doesn't own -- don't mutate
  # someone else's record; disambiguate so save! doesn't hit the unique index.
  def unowned_collision_job_posting(target_url)
    JobPosting.new(target_url: target_url, signature: Digest::SHA256.hexdigest("#{target_url}-lead-#{@lead.id}"))
  end

  def apply_job_posting_attributes(job, company, source)
    job.assign_attributes(@params.slice(:title, :location, :body, :data))
    job.company_id = company&.id
    job.source_id = source.id
  end

  def link_lead(job_posting, company, source)
    @lead.update!(job_posting: job_posting, company: company, source: source)
    @lead.promote! if @lead.may_promote?
  end

  def enqueue_pipeline(job_posting)
    JobBoards::AnalysisJob.perform_later(job_posting.id)
    LLM::ProfileMatchJob.perform_later(@user.id, job_posting.id)
    JobBoards::StrategyJob.perform_later(job_posting.id, @user.id)
  end
end
