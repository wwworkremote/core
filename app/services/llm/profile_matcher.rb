# frozen_string_literal: true

# Service to match a User's career profile against a specific JobPosting.
# It leverages multi-document resume analysis and structured work experience.
class LLM::ProfileMatcher
  # "expert Ruby negotiator" used to sit in this string, and it biased every
  # scan regardless of the posting's actual stack. Scoring a Go/TypeScript role
  # that mentions Ruby zero times, it reported "the role emphasizes Ruby and
  # Rails" as the top strength and tagged the posting ruby-heavy -- inflating
  # the score on a stack the candidate does not match. The persona must not
  # name a language.
  SYSTEM_RULES = "You are a rigorous technical career advisor and interview coach."

  # The anti-fabrication clause mirrors LLM::AnswerGenerator, which always had
  # one. Without it the STAR prep invented credentials to fit the posting --
  # claiming Go backend services and a Principal title at an employer where
  # neither is true. Prep the candidate cannot honestly say in a room is worse
  # than no prep.
  TASK_INSTRUCTIONS = "Return a structured markdown analysis. Be honest, critical, and " \
                      "preparation-oriented. Assess against the posting's actual stack and " \
                      "requirements, not a preferred one. Never claim experience, titles, or " \
                      "technologies the candidate profile does not contain; name gaps as gaps."

  # Executes the deep alignment scan and preparation.
  # @param user [User] The candidate being evaluated.
  # @param job_posting [JobPosting] The opportunity to analyze.
  # @param force [Boolean] Skip staleness check if true.
  # @return [Hash] Success status and structured analysis output.
  def self.call(user, job_posting, force: false)
    new(user, job_posting, force: force).call
  end

  def initialize(user, job_posting, force: false)
    @user = user
    @job_posting = job_posting
    @force = force
    @profile = user.career_profile
  end

  def call
    guard = validate
    return guard if guard

    user_job = @user.user_job_postings.find_or_create_by!(job_posting: @job_posting)
    result = call_orchestrator
    handle_result(result, user_job)
  end

  private

  def call_orchestrator
    prompt = PromptBuilder.call(@profile, @job_posting)
    LLM::Orchestrator.call(untrusted_text: prompt, system_rules: SYSTEM_RULES, task_instructions: TASK_INSTRUCTIONS)
  end

  def validate
    # Shield: Do not process alignment for expired/stale jobs unless forced
    return expired_error if @job_posting.expired? && !@force
    return incomplete_profile_error if profile_incomplete?

    nil
  end

  def expired_error
    { success: false, error: "Job posting is expired/stale. Analysis aborted." }
  end

  def profile_incomplete?
    !profile_signal_present?
  end

  def profile_signal_present?
    return false unless @profile

    @profile.resume_text.present? || @profile.work_experiences.any? || @profile.resumes.attached?
  end

  def incomplete_profile_error
    log_incomplete_profile
    { success: false, error: "Profile incomplete. Please set up your resume." }
  end

  def log_incomplete_profile
    Rails.logger.warn "[ProfileMatcher] Profile incomplete for User ##{@user.id}: #{profile_completeness_summary}"
  end

  def profile_completeness_summary
    "resume_text: #{@profile&.resume_text.present?}, work_experiences: #{@profile&.work_experiences&.any?}, " \
      "resumes_attached: #{@profile&.resumes&.attached?}"
  end

  def handle_result(result, user_job)
    return failure_result(result) unless result[:success] && result[:output].present?

    apply_result(result, user_job)
  end

  def apply_result(result, user_job)
    score = extract_score(result[:output])
    tags = extract_tags(result[:output])
    user_job.update!(match_analysis: result[:output], match_score: score, match_tags: tags,
                     priority_flag: score >= 80)
    { success: true, output: result[:output], score: score, tags: tags }
  end

  # Try to extract numerical score (e.g. 85%)
  def extract_score(output)
    match = output.match(/MATCH_CONFIDENCE.*?(\d+)%/i)
    match ? match[1].to_i : 0
  end

  # TAGS line is comma-separated kebab-case tokens (see PromptBuilder's
  # OUTPUT_FORMAT) -- strip markdown bold/bullet noise the LLM sometimes
  # wraps the line in, then split on commas.
  def extract_tags(output)
    match = output.match(/TAGS\**:?\**\s*(.+)/i)
    return [] unless match

    match[1].split(",").map { |tag| tag.strip.gsub(/[*_`]/, "") }.compact_blank
  end

  def failure_result(result)
    error_msg = result[:error] || "LLM returned empty response"
    Rails.logger.error "[ProfileMatcher] Failed for Job #{@job_posting.id}: #{error_msg}"
    { success: false, error: error_msg }
  end
end
