# frozen_string_literal: true

require 'ruby_llm'
require 'benchmark'
require 'ostruct'

puts "--- RubyLLM + llama.cpp Infrastructure Validation ---"

# 1. Configuration
RubyLLM.configure do |config|
  config.ollama_api_base = ENV['OLLAMA_API_BASE'] || 'http://127.0.0.1:8080/v1'
end

# 2. Health Check
puts "Target: #{RubyLLM.config.ollama_api_base}"
puts "Model: local (Qwen 2.5 Coder 7B)"

client = RubyLLM::Providers::Ollama.new(RubyLLM.config)

# Helper to wrap hash in object for RubyLLM's internal expectation
def msg(role, content)
  OpenStruct.new(role: role, content: content, tool_calls: nil, tool_call_id: nil, thinking_text: nil, thinking_signature: nil)
end

puts "Executing Health Check Prompt (Complete)..."
time = Benchmark.realtime do
  begin
    response = client.complete(
      [msg('user', "Respond with the single word 'NEURAL_LINK_ESTABLISHED' if you are online.")],
      model: OpenStruct.new(id: 'local'),
      tools: [],
      temperature: 0.7
    )
    puts "Response: #{response.content.strip}"
  rescue StandardError => e
    puts "FAILED: #{e.message}"
    puts e.backtrace.first(5)
  end
end

puts "Latency: #{time.round(2)}s"
puts "--- Status: #{time < 15 ? 'OPTIMAL' : 'DEGRADED'} ---"
