# frozen_string_literal: true

# Local interop entry point for other on-box tools/agents (e.g. the just3ws
# CLI) to query and score job postings against the one local User's profile.
# Reads are unrestricted; writes (LLM calls that persist match analysis or
# generate artifacts) require --escalate. --source is required on every call
# purely for attribution in the Rails log -- this is a local single-user app,
# not an authentication boundary. See docs/agents/interop.md.
class Wwwr::Interop
  def self.call(id, filters)
    new(id, filters).call
  end

  def initialize(id, filters)
    @id = id
    @filters = filters
  end

  def call
    return "Missing --source=<name> (required for attribution logging)." unless @filters[:source]

    posting = JobPosting.find_by(id: @id)
    return "Posting ##{@id} not found." unless posting

    log_call
    @filters[:escalate] ? escalate(posting) : read_existing(posting)
  end

  private

  def log_call
    action = @filters[:escalate] ? "escalate" : "read"
    Rails.logger.info "[interop] source=#{@filters[:source]} action=#{action} job_posting=#{@id}"
  end

  def read_existing(posting)
    user_job = User.sole.user_job_postings.find_by(job_posting: posting)
    return "No analysis on file for ##{posting.id}. Pass --escalate to run one." unless user_job&.match_analysis?

    "Score: #{user_job.match_score}  Tags: #{user_job.match_tags&.join(', ')}\n#{user_job.match_analysis}"
  end

  def escalate(posting)
    generator = @filters[:artifact] ? LLM::ArtifactGenerator : LLM::ProfileMatcher
    result = generator.call(User.sole, posting)
    result[:success] ? result[:output] : "Failed: #{result[:error]}"
  end
end
