# frozen_string_literal: true

# RubyLLM expects message-like objects responding to .role/.content/etc --
# a real Struct instead of OpenStruct, per Style/OpenStructUse.
LLM::Orchestrator::ProviderMessage =
  Struct.new(:role, :content, :tool_calls, :tool_call_id, :thinking_text, :thinking_signature)
