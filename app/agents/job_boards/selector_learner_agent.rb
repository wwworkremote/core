# frozen_string_literal: true

# Given a DOM element the user picked out by hand (via the extension's
# element picker) plus a client-computed candidate CSS selector for it,
# proposes the most robust selector reachable from that context. The
# candidate is a safe fallback -- see JobBoards::SelectorLearnerAgent#call's
# caller in Api::ExtractionRulesController, which uses it verbatim if the
# LLM call fails or returns something unusable.
class JobBoards::SelectorLearnerAgent < RubyLLM::Agent
  PROMPT_KEY = "job_boards_selector_learner"

  def call(field_name:, candidate_selector:, element_html:, parent_html:)
    context = build_context(field_name, candidate_selector, element_html, parent_html)
    result = LLM::Orchestrator.call(agent: self, untrusted_text: context, schema: selector_schema,
                                    metadata: { "field_name" => field_name })
    parse_selector(result, candidate_selector)
  end

  def render_instructions
    PipelinePrompt.render_for(PROMPT_KEY) { default_instructions }
  end

  private

  def build_context(field_name, candidate_selector, element_html, parent_html)
    <<~CTX
      FIELD: #{field_name}
      CANDIDATE_SELECTOR: #{candidate_selector}
      ELEMENT_HTML: #{element_html}
      PARENT_HTML: #{parent_html}
    CTX
  end

  def default_instructions
    path = Rails.root.join("app/prompts/job_boards/selector_learner_agent/instructions.txt.erb")
    ERB.new(File.read(path)).result(binding)
  end

  def selector_schema
    { "selector" => String }
  end

  def parse_selector(result, fallback)
    return fallback unless result[:success]

    JSON.parse(result[:output])["selector"].presence || fallback
  rescue JSON::ParserError
    fallback
  end
end
