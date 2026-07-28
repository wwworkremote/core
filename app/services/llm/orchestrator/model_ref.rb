# frozen_string_literal: true

# RubyLLM's client.complete expects a model: object responding to .id.
LLM::Orchestrator::ModelRef = Struct.new(:id)
