# frozen_string_literal: true

module LLMMessagesHelper
  def default_model_display_name
    "Default: #{RubyLLM.models.find(RubyLLM.config.default_model).label}"
  end

  def tool_result_partial(message)
    name = message.respond_to?(:parent_tool_call) ? message.parent_tool_call&.name.to_s : ""
    partial_for(prefix: "llm_messages/tool_results", name: name)
  end

  def tool_call_partial(tool_call)
    partial_for(prefix: "llm_messages/tool_calls", name: tool_call.name.to_s)
  end

  private

  def partial_for(prefix:, name:)
    normalized = name.to_s.underscore.tr("-", "_")
    return "#{prefix}/default" unless normalized.present? && lookup_context.exists?(normalized, [prefix], true)

    "#{prefix}/#{normalized}"
  end
end
