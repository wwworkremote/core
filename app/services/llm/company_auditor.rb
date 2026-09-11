# frozen_string_literal: true

# Service to audit a company's reputation based on Glassdoor feedback and statistics.
# It identifies favorable/neutral/toxic dispositions and flags cultural red flags.
class LLM::CompanyAuditor
  PROMPT_KEY = "company_auditor"

  def self.call(company, raw_feedback)
    new(company, raw_feedback).call
  end

  def initialize(company, raw_feedback)
    @company = company
    @raw_feedback = raw_feedback
  end

  def call
    return { success: false, error: "No feedback provided." } if @raw_feedback.blank?

    handle_result(request_audit)
  end

  private

  # One cohesive orchestrator call -- splitting it further would obscure
  # it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def request_audit
    LLM::Orchestrator.call(
      untrusted_text: audit_prompt,
      system_rules: "You are a ruthless corporate culture auditor. " \
                    "You prioritize candidate well-being over corporate PR.",
      task_instructions: "Return JSON only. Be clinical and accurate."
    )
  end

  def handle_result(result)
    return { success: false, error: result[:error] } unless result[:success]

    apply_audit(parse_audit(result[:output]))
    { success: true }
  end

  def parse_audit(output)
    JSON.parse(output.match(/\{.*\}/m)[0])
  rescue StandardError
    nil
  end

  # One cohesive update! call -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def apply_audit(parsed)
    return unless parsed

    @company.update!(
      disposition: parsed["disposition"],
      sentiment_score: parsed["sentiment_score"],
      toxic_culture_flag: parsed["toxic_culture_flag"],
      glassdoor_data: @company.glassdoor_data.to_h.merge(
        "reputation_audit" => parsed,
        "audited_at" => Time.current
      )
    )
  end

  # Admin-editable via PipelinePrompt (key: "company_auditor"); falls back
  # to #default_audit_prompt when no active override exists.
  def audit_prompt
    PipelinePrompt.render_for(PROMPT_KEY, company_name: @company.name, raw_feedback: @raw_feedback) do
      default_audit_prompt
    end
  end

  def default_audit_prompt
    <<~PROMPT
      [SYSTEM_OBJECTIVE]
      Analyze the following Glassdoor feedback for company: #{@company.name}.
      You are a RUTHLESS CULTURE AUDITOR. Your job is to warn the candidate about toxic work environments
      and highlight truly favorable high-growth engineering cultures.

      [RAW_FEEDBACK]
      #{@raw_feedback}

      [AUDIT_DIMENSIONS]
      1. **DISPOSITION**: Classify as 'Favorable', 'Neutral', 'Struggling', or 'Toxic'.
      2. **SENTIMENT_SCORE**: A value from 0.0 (Worst) to 1.0 (Best).
      3. **TOXIC_CULTURE_FLAGS**: Identify markers like 'micromanagement', 'high turnover', 'gaslighting', 'lack of diversity', or 'death marches'.
      4. **ENGINEERING_PROS_CONS**: What specifically do engineers like or hate?

      [OUTPUT_FORMAT]
      JSON only.
      {
        "disposition": "...",
        "sentiment_score": 0.0,
        "toxic_culture_flag": true/false,
        "summary": "...",
        "top_pros": ["...", "..."],
        "top_cons": ["...", "..."]
      }
    PROMPT
  end
end
