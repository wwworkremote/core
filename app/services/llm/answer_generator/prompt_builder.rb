# frozen_string_literal: true

# Assembles the screening-question-answer prompt for LLM::AnswerGenerator
# from a CareerProfile's structured experience, a JobPosting, and the
# question text -- mirrors LLM::ArtifactGenerator::PromptBuilder's shape.
class LLM::AnswerGenerator::PromptBuilder
  def self.call(...)
    new(...).call
  end

  def initialize(profile, job_posting, question_text)
    @profile = profile
    @job_posting = job_posting
    @question_text = question_text
  end

  def call
    <<~PROMPT
      [OBJECTIVE]
      Answer the following job application screening question in first
      person, as the candidate, using only facts supported by the
      candidate profile below.

      [QUESTION]
      #{@question_text}

      [CANDIDATE_PROFILE]
      Skills: #{@profile.skills}
      Goals: #{@profile.goals}
      History:
      #{experiences}

      [JOB_POSTING]
      Title: #{@job_posting.title}
      Company: #{@job_posting.company}

      [CONSTRAINTS]
      - 2-4 sentences, first person, no headers or markdown formatting.
      - Be specific and confident; don't hedge or pad with generic filler.
      - Do not fabricate facts not present in the profile above.
    PROMPT
  end

  private

  def experiences
    @profile.work_experiences.order(start_date: :desc).map do |exp|
      "#{exp.title} at #{exp.company_name}: #{exp.summary}. Impact: #{exp.impact}"
    end.join("\n")
  end
end
