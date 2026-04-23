# frozen_string_literal: true

module LLM
  class ArtifactGenerator
    def self.call(user, job_posting)
      new(user, job_posting).call
    end

    def initialize(user, job_posting)
      @user = user
      @job_posting = job_posting
      @profile = user.career_profile
    end

    def call
      return { success: false, error: 'Profile incomplete' } unless @profile&.work_experiences&.any?

      prompt = build_cover_letter_prompt

      result = LLM::Orchestrator.call(
        untrusted_text: prompt,
        system_rules: 'You are an elite technical career strategist and ghostwriter.',
        task_instructions: 'Generate a bespoke, high-impact cover letter in markdown format.'
      )

      if result[:success]
        # Attach the generated artifact to the user's job record
        user_job = @user.user_job_postings.find_or_create_by!(job_posting: @job_posting)
        # We can store this in a new field or just return it for now.
        # I will store it in notes or a dedicated field if we add one.
        user_job.update!(notes: "#{user_job.notes}\n\n### [GENERATED_COVER_LETTER]\n#{result[:output]}")
        { success: true, output: result[:output] }
      else
        { success: false, error: result[:error] }
      end
    end

    private

    def build_cover_letter_prompt
      experiences = @profile.work_experiences.order(start_date: :desc).map do |exp|
        "#{exp.title} at #{exp.company_name}: #{exp.summary}. Impact: #{exp.impact}"
      end.join("\n")

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
  end
end
