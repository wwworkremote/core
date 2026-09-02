# frozen_string_literal: true

# `bin/wwwr interview-prep <job_posting_id> [--regenerate]` -- prints the
# stored interview prep pack for a posting, or generates one. Split out of
# Wwwr::CLI to keep that class under Metrics/ClassLength. Single-user app,
# so the pack is read/written against User.sole's UserJobPosting, same
# assumption Wwwr::Interop already makes.
class Wwwr::InterviewPrep
  def self.call(posting, regenerate: false)
    new(posting, regenerate).call
  end

  def initialize(posting, regenerate)
    @posting = posting
    @regenerate = regenerate
  end

  def call
    return stored if stored.present? && !@regenerate

    result = LLM::InterviewPrepGenerator.call(User.sole, @posting, force: true)
    result[:success] ? result[:output] : "Generation failed: #{result[:error]}"
  end

  private

  def stored
    @stored ||= User.sole.user_job_postings.find_by(job_posting: @posting)&.interview_prep_pack.to_s
  end
end
