# frozen_string_literal: true

# Assembles the interview-prep-pack prompt for LLM::InterviewPrepGenerator
# from a CareerProfile's structured experience, a JobPosting, stored Company
# reputation intel, an existing match analysis, and any linked referral
# Contact -- mirrors LLM::ArtifactGenerator::PromptBuilder's shape. The
# section list tracks docs/research/interview-prep-basis-dsp.md.
class LLM::InterviewPrepGenerator::PromptBuilder
  PROMPT_KEY = "interview_prep_pack"

  def self.call(...)
    new(...).call
  end

  def initialize(profile, job_posting, user_job_posting = nil)
    @profile = profile
    @job_posting = job_posting
    @user_job_posting = user_job_posting
  end

  # Admin-editable via PipelinePrompt (key: "interview_prep_pack"); falls
  # back to #default_prompt when no active override exists.
  def call
    PipelinePrompt.render_for(PROMPT_KEY, prompt_locals) { default_prompt }
  end

  private

  def prompt_locals
    { profile: @profile, job_posting: @job_posting, experiences: experiences,
      company_intel: company_intel, match_analysis: match_analysis, referral: referral }
  end

  # rubocop:disable-next Metrics/AbcSize
  def default_prompt
    <<~PROMPT
      [OBJECTIVE]
      Prepare this candidate for an interview for the job posting below. Produce a prep pack
      with these sections, in this order:
      1. THE SETUP -- role summary, team, stack, and an honest reality check on comp/level
         against the candidate's standing criteria (call out an under-level plainly).
      2. YOUR STORY -- a 90-second first-person narrative arc connecting the candidate's real
         history to why this role, ending on what they want next.
      3. COMPANY HOOKS -- 4-6 specific connections between the candidate's experience and this
         company/role, ranked; tell them to use the top 2-3.
      4. THE REFERRAL PLAY -- how to use the internal connection. OMIT THIS SECTION ENTIRELY
         if no referral is listed below.
      5. LIKELY QUESTIONS -- what they will probably ask, including questions that probe the
         candidate's real soft spots (title down-level, gaps, short stints); one-line angle each.
      6. QUESTIONS TO ASK THEM -- including a leveling/comp probe and a culture probe, phrased
         as genuine curiosity.
      7. NIGHT-BEFORE CHECKLIST -- concrete, checkable items.

      [CANDIDATE]
      Level: #{@profile.experience_level}
      Skills: #{@profile.skills}
      Goals: #{@profile.goals}
      History (most recent first):
      #{experiences}

      [STANDING_CRITERIA]
      - Comp floor per config; below that, culture/belonging has to carry real weight.
      - Weight team culture and "genuinely glad to have him" above marginal comp -- a
        first-class factor, not a tiebreaker.
      - US-only. A role that cannot employ a US resident is a hard pass.
      - Level is sized to company stage (Staff/Principal through CTO), not a fixed title.

      [JOB_POSTING]
      Title: #{@job_posting.title}
      Company: #{@job_posting.company_name}
      Location: #{@job_posting.location}
      Body:
      #{@job_posting.body}

      [COMPANY_INTEL]
      #{company_intel}

      [PRIOR_MATCH_ANALYSIS]
      #{match_analysis}

      [REFERRAL]
      #{referral}

      [CONSTRAINTS]
      - Markdown. Second person ("you"), except the STORY section which is first person.
      - Every claim about the candidate must trace to the History above. No invented facts.
      - Be specific, not generic. Name real projects, real numbers, real people.
    PROMPT
  end

  def experiences
    @experiences ||= ordered_experiences.map { |exp| experience_block(exp) }.join("\n\n")
  end

  def ordered_experiences
    @profile.work_experiences.includes(:experience_highlights).order(start_date: :desc).limit(12)
  end

  # Interpolation-dense string builders -- ABC counts every attribute read as
  # a branch. Splitting them into per-field helpers would relocate lines to
  # satisfy the metric, not make them clearer.
  # rubocop:disable Metrics/AbcSize
  def experience_block(exp)
    <<~EXP
      ### #{exp.title} at #{exp.company_name} (#{exp.start_date} - #{exp.end_date || 'Present'})
      #{exp.summary}
      Action: #{exp.action} | Impact: #{exp.impact}
      #{exp.experience_highlights.map { |h| "- [#{h.label}] #{h.text}" }.join("\n")}
    EXP
  end

  # Whatever LLM::CompanyAuditor already stored -- no live web research here.
  # ponytail: stored Company audit + posting text only; add a research step
  # if packs come out thin on company specifics.
  def company_intel
    company = Company.find_by(id: @job_posting.company_id)
    audit = company&.glassdoor_data.to_h["reputation_audit"]
    return "None on file." if audit.blank?

    "#{audit['summary']}\nPros: #{Array(audit['top_pros']).join('; ')}\n" \
      "Cons: #{Array(audit['top_cons']).join('; ')}"
  end

  def match_analysis
    @user_job_posting&.match_analysis.presence || "None on file."
  end

  # Contacts are Mike's own logged referrals, not scraped third-party text.
  def referral
    listed = @job_posting.contacts.map { |c|
      "#{c.name} (#{c.relationship_type.presence || c.role.presence || 'connection'})"
    }
    listed.any? ? listed.join("\n") : "None listed -- omit the referral section."
  end
  # rubocop:enable Metrics/AbcSize
end
