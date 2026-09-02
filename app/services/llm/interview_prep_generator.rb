# frozen_string_literal: true

# Generates a bespoke interview prep pack for one (candidate, posting) pair
# and stores it on the UserJobPosting -- the same shape as
# LLM::ArtifactGenerator (cover letter), guarded the same way. Grounds the
# pack in the candidate's structured history, the posting text, any stored
# Company reputation audit, and any linked referral Contact. The worked
# reference that defines the section structure is
# docs/research/interview-prep-basis-dsp.md.
class LLM::InterviewPrepGenerator
  SYSTEM_RULES = "You are an elite technical interview coach and career strategist. " \
                 "You prepare a specific candidate for a specific interview."
  TASK_INSTRUCTIONS = "Produce a bespoke interview prep pack in markdown, using the section " \
                      "structure named in the objective. Ground every claim in the candidate " \
                      "facts provided; never invent a title, date, employer, or metric."

  def self.call(user, job_posting, force: false, spoken: true)
    new(user, job_posting, force: force, spoken: spoken).call
  end

  def initialize(user, job_posting, force: false, spoken: true)
    @user = user
    @job_posting = job_posting
    @profile = user.career_profile
    @force = force
    @spoken = spoken
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
    prompt = PromptBuilder.call(@profile, @job_posting, user_job_posting)
    LLM::Orchestrator.call(untrusted_text: prompt, system_rules: SYSTEM_RULES,
                           task_instructions: TASK_INSTRUCTIONS, model: prep_model)
  end

  # Interview prep is prose read by Mike, not code, and carries no untrusted
  # third-party text beyond the posting body (which the orchestrator already
  # screens) -- so it can opt onto a stronger prose model the same way
  # answer_generation does. Set `defaults.interview_prep` in
  # config/models.yml; unset, it uses the primary and nothing changes.
  def prep_model
    LLM::Registry.model_for(:interview_prep)
  end

  def handle_result(result)
    return { success: false, error: result[:error] } unless result[:success]

    user_job_posting.update!(interview_prep_pack: result[:output],
                             interview_prep_pack_spoken: spoken_version(result[:output]),
                             interview_prep_pack_generated_at: Time.current)
    { success: true, output: result[:output] }
  end

  # Second pass: a read-aloud rewrite of the just-generated human pack, so the
  # two versions carry identical content. Non-fatal -- a failed rewrite leaves
  # the spoken column nil, the human pack still lands.
  def spoken_version(human_pack)
    return unless @spoken

    SpokenRewriter.call(human_pack)
  end

  def user_job_posting
    @user_job_posting ||= @user.user_job_postings.find_or_create_by!(job_posting: @job_posting)
  end
end
