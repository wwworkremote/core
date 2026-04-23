# frozen_string_literal: true

module LLM
  class CareerComparator
    def self.call(user, job_postings)
      new(user, job_postings).call
    end

    def initialize(user, job_postings)
      @user = user
      @job_postings = job_postings.first(3) # Limit to 3 for granular comparison
      @profile = user.career_profile
    end

    def call
      return { success: false, error: 'Need at least 2 jobs to compare.' } if @job_postings.count < 2

      prompt = <<~PROMPT
        [SYSTEM_OBJECTIVE]
        Perform a comparative semantic analysis between the candidate's profile and several potential job opportunities.
        Identify the 'Path of Least Resistance' to a high-impact remote Ruby role.

        [CANDIDATE]
        #{profile_context}

        [OPPORTUNITIES]
        #{jobs_context}

        [COMPARISON_DIMENSIONS]
        1. **STABILITY_VS_GROWTH**: Which role offers the best balance?
        2. **TECH_DEBT_RISK**: Based on descriptions, which company seems more technically mature?
        3. **COMPENSATION_POTENTIAL**: Inferred value based on role seniority and company tier.
        4. **INTERVIEW_DIFFICULTY**: Predicted friction in the hiring process.

        [OUTPUT_FORMAT]
        1. **RANKING**: Ordered list (1, 2, 3) with a one-sentence justification for each.
        2. **STRATEGIC_WINNER**: Which role should the user prioritize today?
        3. **APPLICATION_SEQUENCE**: In what order should the user apply to maximize leverage?
      PROMPT

      LLM::Orchestrator.call(
        untrusted_text: prompt,
        system_rules: 'You are a strategic career consultant and game-theory expert in technical hiring.',
        task_instructions: 'Return a sharp, comparative analysis in markdown.'
      )
    end

    private

    def profile_context
      <<~CTX
        Skills: #{@profile.skills}
        Goals: #{@profile.goals}
        Experience: #{@profile.experience_level}
      CTX
    end

    def jobs_context
      @job_postings.map.with_index do |job, i|
        <<~JOB
          --- JOB #{i + 1} ---
          Title: #{job.title}
          Company: #{job.company}
          URL: #{job.target_url}
          Summary: #{job.body&.truncate(500)}
        JOB
      end.join("\n\n")
    end
  end
end
