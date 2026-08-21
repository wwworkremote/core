# frozen_string_literal: true

# Answers an already-persisted ApplicationQuestion -- tries a deterministic
# CannedAnswers match first (instant, no LLM call), and only falls to the
# LLM::Orchestrator path (guarded the same way as ArtifactGenerator/
# ProfileMatcher) when no canned pattern applies. Does not create the
# question itself -- that's the controller's job, so a typed question
# always persists even if answer generation fails.
class LLM::AnswerGenerator
  SYSTEM_RULES = "You are an elite technical career strategist, writing first-person application answers."
  TASK_INSTRUCTIONS = "Answer the applicant's screening question directly, in first person, in 2-4 sentences."

  def self.call(question, force: false)
    new(question, force: force).call
  end

  def initialize(question, force: false)
    @question = question
    @user = question.user
    @job_posting = question.job_posting
    @profile = @user.career_profile
    @force = force
  end

  def call
    canned_answer = CannedAnswers.match(@question.question_text, @profile)
    return apply_answer(canned_answer, "canned") if canned_answer

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
    { success: false, error: "Job posting is expired/stale. Answer generation aborted." }
  end

  def call_orchestrator
    prompt = PromptBuilder.call(@profile, @job_posting, @question.question_text)
    LLM::Orchestrator.call(untrusted_text: prompt, system_rules: SYSTEM_RULES,
                           task_instructions: TASK_INSTRUCTIONS, model: answer_model)
  end

  # Screening answers are the opposite profile to ingestion: low volume, no
  # untrusted third-party text, no PHI exposure, and the output goes to an
  # employer -- so quality matters more than keeping the call on-box, which
  # is the reverse of the trade that makes local-first right everywhere else.
  # Set `defaults.answer_generation` in config/models.yml to opt this one
  # path onto a stronger model; unset, it uses the primary like everything
  # else and nothing changes.
  def answer_model
    LLM::Registry.model_for(:answer_generation)
  end

  def handle_result(result)
    return { success: false, error: result[:error] } unless result[:success]

    apply_answer(result[:output], "ai")
  end

  def apply_answer(answer, source)
    @question.update!(answer_text: answer, answer_source: source)
    { success: true, answer: answer, source: source }
  end
end
