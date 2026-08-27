# frozen_string_literal: true

# BPMN "Service Task": proposes a resume persona for a JobPosting, but never
# sets one -- it only ever creates a pending HumanTask for a person to
# approve, edit, or reject. Codifies the same judgment made by hand for
# JobPosting #6828 (Karias Health -> founding_staff_fullstack) and #6830
# (AbbVie -> observability_resilience_specialist) during the 2026-08-27 live
# pipeline test: read the posting's actual scope, not just its title, and
# say why a persona fits before proposing it.
class Pipeline::PersonaRecommender
  def self.call(...)
    new(...).call
  end

  SYSTEM_RULES = "You recommend which of a candidate's resume personas best fits a specific job " \
                 "posting. You are skeptical of surface-level title matches -- a posting titled " \
                 "\"Senior Software Engineer\" can be Staff/Principal-scoped in substance (a " \
                 "foundational hire owning architecture end-to-end), and a posting titled " \
                 "\"Director\" can be a pure IC role in disguise. Read what the role actually asks " \
                 "the person to own and decide, not the title."

  TASK_INSTRUCTIONS = "Pick exactly one persona ID from the list, or the literal string \"none\" if " \
                      "none fit well. Respond in this exact format, nothing else:\n" \
                      "PERSONA_ID: <id or none>\n" \
                      "CONFIDENCE: <0-100>\n" \
                      "RATIONALE: <one sentence, citing specific language from the posting>"

  def initialize(job_posting:, user:)
    @job_posting = job_posting
    @user = user
  end

  # Idempotent: re-running while a persona_review task is already pending for
  # this posting returns the existing task rather than piling up duplicates.
  def call
    existing = @job_posting.human_tasks.open.find_by(kind: "persona_review")
    return existing if existing

    HumanTask.create!(job_posting: @job_posting, user: @user, kind: "persona_review",
                      proposed_by: "ai", payload: recommendation)
  end

  private

  def recommendation
    result = LLM::Orchestrator.call(untrusted_text: prompt, system_rules: SYSTEM_RULES,
                                    task_instructions: TASK_INSTRUCTIONS)
    parse(result)
  end

  def prompt
    <<~PROMPT
      [JOB POSTING]
      Title: #{@job_posting.title}
      Company: #{company_name}
      Description: #{@job_posting.body}

      [CANDIDATE PERSONAS]
      #{persona_lines}
    PROMPT
  end

  # JobPosting#company is deliberately polymorphic (see
  # JobPosting::LegacyCompanyAccess) -- a resolved Company record once one
  # exists, otherwise the free-text company_name string. Normalize to a
  # plain string either way.
  def company_name
    company = @job_posting.company
    company.is_a?(Company) ? company.name : company
  end

  def persona_lines
    Resume::PersonaContext.personas.map { |p| "- #{p[:id]}: #{p[:title]} -- #{p[:summary]}" }.join("\n")
  end

  def parse(result)
    text = result.is_a?(Hash) ? result[:output].to_s : result.to_s
    { "persona_id" => text[/PERSONA_ID:\s*(\S+)/, 1], "confidence" => text[/CONFIDENCE:\s*(\d+)/, 1]&.to_i,
      "rationale" => text[/RATIONALE:\s*(.+)/, 1]&.strip, "raw" => text }
  end
end
