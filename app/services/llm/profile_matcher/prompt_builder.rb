# frozen_string_literal: true

# Assembles the deep-alignment-scan prompt for LLM::ProfileMatcher from a
# CareerProfile's structured experience, attached documents, and GitHub
# context against a JobPosting -- split out to keep ProfileMatcher itself
# under Metrics/ClassLength.
class LLM::ProfileMatcher::PromptBuilder
  def self.call(...)
    new(...).call
  end

  def initialize(profile, job_posting)
    @profile = profile
    @job_posting = job_posting
  end

  # One cohesive template with many interpolated fields -- splitting it
  # would fragment a single prompt into unreadable pieces for no real
  # simplification, so the AbcSize overage here is accepted rather than
  # mechanically chased.
  # rubocop:disable Metrics/AbcSize
  def call
    <<~PROMPT
      [SYSTEM_OBJECTIVE]
      Perform a deep semantic alignment scan between the following CANDIDATE_PROFILE and JOB_POSTING.
      You are a RUTHLESS CAREER ADVOCATE and INTERVIEW COACH. Your job is to identify PERFECT matches and prepare the user to win.

      [CANDIDATE_PROFILE]
      Tier: #{@profile.experience_level}
      Skills: #{@profile.skills}
      Goals: #{@profile.goals}

      [STRUCTURED_EXPERIENCE]
      #{experiences_context}

      [TECHNICAL_EVIDENCE_GITHUB]
      #{@profile.github_context&.dig('synthesis') || 'No GitHub context available.'}

      [ATTACHED_DOCUMENTS]
      #{extra_documents}

      [JOB_POSTING]
      Title: #{@job_posting.title}
      Company: #{@job_posting.company}
      Description: #{@job_posting.body}

      [CRITICAL_EVALUATION_CRITERIA]
      1. **REMOTE_PURITY**: Is this truly remote? Penalize 'hybrid' or 'occasional travel'.
      2. **TECH_STACK_DENSITY**: How much Ruby/Rails focus is there? Reject 'full-stack' if it's 90% React/Node.
      3. **SENIORITY_ALIGNMENT**: Does this role offer the autonomy expected for a #{@profile.experience_level} level?
      4. **RED_FLAGS**: Identify signs of toxic culture, legacy tech debt, or unrealistic expectations.

      [OUTPUT_FORMAT]
      1. **MATCH_CONFIDENCE**: (0-100%)
      2. **STRENGTHS**: Why this aligns with the user's stated goals.
      3. **WEAKNESSES**: Why the user might want to SKIP this opportunity.
      4. **RESUME_DELTA**: The exact technical bullet points to add/tweak if the user decides to apply.
      5. **INTERVIEW_PREP**: 3 custom technical questions they will likely ask, and the 'STAR' method responses the user should give based on their experience.
    PROMPT
  end
  # rubocop:enable Metrics/AbcSize

  private

  def experiences_context
    top_experiences.map { |exp| experience_block(exp) }.join("\n\n")
  end

  def top_experiences
    @profile.work_experiences.includes(:experience_highlights).order(start_date: :desc).limit(10)
  end

  def experience_block(exp)
    <<~EXP
      ### #{exp.title} at #{exp.company_name}
      Dates: #{exp.start_date} to #{exp.end_date || 'Present'}
      Summary: #{exp.summary}
      Action: #{exp.action}
      Impact: #{exp.impact}
      Highlights:
      #{experience_highlights(exp)}
    EXP
  end

  def experience_highlights(exp)
    exp.experience_highlights.map { |h| "- [#{h.label}] #{h.text}" }.join("\n")
  end

  # Include multi-document resume content
  def extra_documents
    LLM::DocumentProcessor.extract_pdf_text_for_all(@profile).map do |doc|
      "--- DOCUMENT: #{doc[:filename]} ---\n#{doc[:content]}"
    end.join("\n\n")
  end
end
