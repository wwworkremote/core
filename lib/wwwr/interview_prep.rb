# frozen_string_literal: true

# `bin/wwwr interview-prep <job_posting_id> [--regenerate] [--spoken]` --
# prints the stored interview prep pack for a posting, or generates one.
# `--spoken` prints the read-aloud version instead of the human one. Split
# out of Wwwr::CLI to keep that class under Metrics/ClassLength. Single-user
# app, so the pack is read/written against User.sole's UserJobPosting, same
# assumption Wwwr::Interop already makes.
class Wwwr::InterviewPrep
  def self.call(posting, regenerate: false, spoken: false)
    new(posting, regenerate, spoken).call
  end

  def initialize(posting, regenerate, spoken)
    @posting = posting
    @regenerate = regenerate
    @spoken = spoken
  end

  def call
    generate unless fresh_pack_exists?
    @error || printed_pack
  end

  private

  def fresh_pack_exists?
    record&.interview_prep_pack.present? && !@regenerate
  end

  # After a fresh generation prefer @generated (the human output just produced)
  # over the DB read; the read-aloud column is only available through the record.
  def printed_pack
    stored = @spoken ? record&.interview_prep_pack_spoken : (@generated || record&.interview_prep_pack)
    stored.to_s.presence || missing_hint
  end

  def generate
    result = LLM::InterviewPrepGenerator.call(User.sole, @posting, force: true)
    return @error = "Generation failed: #{result[:error]}" unless result[:success]

    @generated = result[:output]
  end

  def record
    User.sole.user_job_postings.find_by(job_posting: @posting)
  end

  def missing_hint
    @spoken ? "(no read-aloud version -- regenerate to build one)" : ""
  end
end
