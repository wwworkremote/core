# frozen_string_literal: true

module Llm
  class ProfileMatcher
    def self.call(user, job_posting)
      profile = user.career_profile
      return { success: false, error: "Profile incomplete. Please set up your resume." } unless profile&.resume_text.present?

      user_job = user.user_job_postings.find_or_create_by!(job_posting: job_posting)

      prompt = <<~PROMPT
        [SYSTEM_OBJECTIVE]
        Perform a deep semantic alignment scan between the following CANDIDATE_PROFILE and JOB_POSTING.
        Provide a technical analysis of fit, specific gaps, and actionable resume optimization advice.

        [CANDIDATE_PROFILE]
        Tier: #{profile.experience_level}
        Skills: #{profile.skills}
        Goals: #{profile.goals}
        Resume_Data: #{profile.resume_text}

        [JOB_POSTING]
        Title: #{job_posting.title}
        Company: #{job_posting.company}
        Description: #{job_posting.body}

        [OUTPUT_FORMAT]
        1. **MATCH_CONFIDENCE**: (0-100%)
        2. **STRENGTHS**: Top 3 reasons for alignment.
        3. **GAPS**: Technical or experience deficiencies.
        4. **RESUME_DELTA**: Specific advice to tailor the resume for this role.
      PROMPT

      result = Llm::Orchestrator.call(
        untrusted_text: prompt,
        system_rules: "You are a senior technical recruiter and career strategist.",
        task_instructions: "Return a structured markdown analysis of the match."
      )

      if result[:success]
        user_job.update!(match_analysis: result[:output])
        { success: true, output: result[:output] }
      else
        { success: false, error: result[:error] }
      end
    end
  end
end
