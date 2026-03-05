# frozen_string_literal: true

RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials[:openai_api_key]
  config.anthropic_api_key = ENV['ANTHROPIC_API_KEY'] || Rails.application.credentials[:anthropic_api_key]
  config.gemini_api_key = ENV['GEMINI_API_KEY'] || Rails.application.credentials[:gemini_api_key]
  config.ollama_api_base = ENV['OLLAMA_API_BASE'] || 'http://localhost:11434'

  # config.default_model = "gpt-4.1-nano"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end

# Ensure ActiveRecord is extended if the Railtie didn't do it
ActiveSupport.on_load(:active_record) do
  extend RubyLLM::ActiveRecord::ActsAs
end
