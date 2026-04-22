# frozen_string_literal: true

module LLM
  class ProfileMatcher
    def self.call(user, job_posting)
      profile = user.career_profile
      
      # Debug logging for incomplete profiles
      unless profile&.resume_text.present? || profile&.work_experiences&.any? || profile&.resumes&.attached?
        Rails.logger.warn "[ProfileMatcher] Profile incomplete for User ##{user.id}: " \
                          "resume_text: #{profile&.resume_text.present?}, " \
                          "work_experiences: #{profile&.work_experiences&.any?}, " \
                          "resumes_attached: #{profile&.resumes&.attached?}"
        return { success: false, error: "Profile incomplete. Please set up your resume." }
      end

      user_job = user.user_job_postings.find_or_create_by!(job_posting: job_posting)

      # Build structured experience context
      experiences_context = profile.work_experiences.order(start_date: :desc).limit(10).map do |exp|
        highlights = exp.experience_highlights.map { |h| "- [#{h.label}] #{h.text}" }.join("\n")
        <<~EXP
          ### #{exp.title} at #{exp.company_name}
          Dates: #{exp.start_date} to #{exp.end_date || 'Present'}
          Summary: #{exp.summary}
          Action: #{exp.action}
          Impact: #{exp.impact}
          Highlights:
          #{highlights}
        EXP
      end.join("\n\n")

      # Include multi-document resume content
      extra_documents = LLM::DocumentProcessor.extract_pdf_text_for_all(profile).map do |doc|
        "--- DOCUMENT: #{doc[:filename]} ---\n#{doc[:content]}"
      end.join("\n\n")

      prompt = <<~PROMPT
        [SYSTEM_OBJECTIVE]
        Perform a deep semantic alignment scan between the following CANDIDATE_PROFILE and JOB_POSTING.
        You are a RUTHLESS CAREER ADVOCATE and INTERVIEW COACH. Your job is to identify PERFECT matches and prepare the user to win.

        [CANDIDATE_PROFILE]
        Tier: #{profile.experience_level}
        Skills: #{profile.skills}
        Goals: #{profile.goals}
        
        [STRUCTURED_EXPERIENCE]
        #{experiences_context}

        [ATTACHED_DOCUMENTS]
        #{extra_documents}

        [JOB_POSTING]
        Title: #{job_posting.title}
        Company: #{job_posting.company}
        Description: #{job_posting.body}

        [CRITICAL_EVALUATION_CRITERIA]
        1. **REMOTE_PURITY**: Is this truly remote? Penalize 'hybrid' or 'occasional travel'.
        2. **TECH_STACK_DENSITY**: How much Ruby/Rails focus is there? Reject 'full-stack' if it's 90% React/Node.
        3. **SENIORITY_ALIGNMENT**: Does this role offer the autonomy expected for a #{profile.experience_level} level?
        4. **RED_FLAGS**: Identify signs of toxic culture, legacy tech debt, or unrealistic expectations.

        [OUTPUT_FORMAT]
        1. **MATCH_CONFIDENCE**: (0-100%)
        2. **STRENGTHS**: Why this aligns with the user's stated goals.
        3. **WEAKNESSES**: Why the user might want to SKIP this opportunity.
        4. **RESUME_DELTA**: The exact technical bullet points to add/tweak if the user decides to apply.
        5. **INTERVIEW_PREP**: 3 custom technical questions they will likely ask, and the 'STAR' method responses the user should give based on their experience.
      PROMPT

      result = LLM::Orchestrator.call(
        untrusted_text: prompt,
        system_rules: "You are a ruthless technical career advocate, expert Ruby negotiator, and elite interview coach.",
        task_instructions: "Return a structured markdown analysis. Be honest, critical, and preparation-oriented."
      )

      if result[:success] && result[:output].present?
        user_job.update!(match_analysis: result[:output])
        
        # Try to extract numerical score (e.g. 85%)
        score_match = result[:output].match(/MATCH_CONFIDENCE.*?(\d+)%/i)
        score = 0
        if score_match
          score = score_match[1].to_i
          user_job.update!(priority_flag: true) if score >= 80
        end

        { success: true, output: result[:output], score: score }
      else
        error_msg = result[:error] || "LLM returned empty response"
        Rails.logger.error "[ProfileMatcher] Failed for Job #{job_posting.id}: #{error_msg}"
        { success: false, error: error_msg }
      end
    end
  end
end
