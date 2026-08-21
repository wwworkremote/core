# frozen_string_literal: true

# RubyLLM expects message-like objects responding to .role/.content/etc --
# a real Struct instead of OpenStruct, per Style/OpenStructUse.
#
# The two predicates aren't decoration. RubyLLM's Anthropic provider calls
# `msg.tool_call?` on every message it formats, so without them any Anthropic
# request dies with NoMethodError before it leaves the process. The
# Ollama/OpenAI path never calls them, which is why the local default worked
# and the configured Claude model had never actually run. Semantics copied
# from RubyLLM::Message so the two can't disagree.
#
# Not implemented: `#thinking`, which Anthropic also calls -- but only when
# extended thinking is enabled, and nothing here enables it. Add it (wrapping
# thinking_text/thinking_signature in something responding to .text and
# .signature) if that changes.
LLM::Orchestrator::ProviderMessage =
  Struct.new(:role, :content, :tool_calls, :tool_call_id, :thinking_text, :thinking_signature) do
    def tool_call?
      tool_calls.present?
    end

    def tool_result?
      tool_call_id.present?
    end
  end
