# frozen_string_literal: true

# Assembles the cover-letter prompt for LLM::ArtifactGenerator from a
# CareerProfile's structured experience and a JobPosting -- split out to
# keep ArtifactGenerator itself under Metrics/MethodLength.
class LLM::ArtifactGenerator::PromptBuilder
  def self.call(...)
    new(...).call
  end

  def initialize(profile, job_posting)
    @profile = profile
    @job_posting = job_posting
  end

  def call
    <<~PROMPT
      [OBJECTIVE]
      Generate a bespoke, high-impact cover letter for the following job posting.
      Focus on how my specific technical actions and business impacts (from my history) directly address their needs.

      [CANDIDATE_PROFILE]
      Skills: #{@profile.skills}
      Goals: #{@profile.goals}
      History:
      #{experiences}

      [JOB_POSTING]
      Title: #{@job_posting.title}
      Company: #{@job_posting.company}
      Body: #{@job_posting.body}

      [CONSTRAINTS]
      - Keep it under 400 words.
      - Tone: Professional, authoritative, yet approachable.
      - Avoid generic fluff; use specific metrics from the History.
      - Format: Markdown.
    PROMPT
  end

  private

  def experiences
    @profile.work_experiences.order(start_date: :desc).map do |exp|
      "#{exp.title} at #{exp.company_name}: #{exp.summary}. Impact: #{exp.impact}"
    end.join("\n")
  end
end
