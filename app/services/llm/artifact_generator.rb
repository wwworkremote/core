# frozen_string_literal: true

class LLM::ArtifactGenerator
  SYSTEM_RULES = "You are an elite technical career strategist and ghostwriter."
  TASK_INSTRUCTIONS = "Generate a bespoke, high-impact cover letter in markdown format."

  def self.call(user, job_posting, force: false)
    new(user, job_posting, force: force).call
  end

  def initialize(user, job_posting, force: false)
    @user = user
    @job_posting = job_posting
    @profile = user.career_profile
    @force = force
  end

  def call
    guard = validate
    return guard if guard

    handle_result(call_orchestrator)
  end

  private

  def validate
    return incomplete_profile_error unless @profile&.work_experiences&.any?
    return expired_error if @job_posting.expired? && !@force

    nil
  end

  def incomplete_profile_error
    { success: false, error: "Profile incomplete" }
  end

  def expired_error
    { success: false, error: "Job posting is expired/stale. Generation aborted." }
  end

  def call_orchestrator
    prompt = PromptBuilder.call(@profile, @job_posting)
    LLM::Orchestrator.call(untrusted_text: prompt, system_rules: SYSTEM_RULES, task_instructions: TASK_INSTRUCTIONS)
  end

  def handle_result(result)
    return { success: false, error: result[:error] } unless result[:success]

    attach_artifact(result)
  end

  def attach_artifact(result)
    user_job = @user.user_job_postings.find_or_create_by!(job_posting: @job_posting)
    user_job.update!(notes: "#{user_job.notes}\n\n### [GENERATED_COVER_LETTER]\n#{result[:output]}")
    { success: true, output: result[:output] }
  end
end
