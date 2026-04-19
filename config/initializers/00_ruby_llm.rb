# frozen_string_literal: true

RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.dig(:openai_api_key) || 'sk-local'
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY'] || Rails.application.credentials.dig(:anthropic_api_key)
  config.gemini_api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials.dig(:gemini_api_key)

  # Default to host llama.cpp server
  config.ollama_api_base = ENV['OLLAMA_API_BASE'] || 'http://localhost:8080/v1'

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end

# Ensure ActiveRecord is extended if the Railtie didn't do it
ActiveSupport.on_load(:active_record) do
  extend RubyLLM::ActiveRecord::ActsAs
end
