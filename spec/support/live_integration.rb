# frozen_string_literal: true

# spec/support/live_integration.rb
#
# Specs tagged `live: true` hit real external services (llama.cpp server,
# network APIs). They are excluded from the normal suite by default.
#
# Run them explicitly:
#   bundle exec rspec --tag live
#
# They are intentionally NOT wired into CI because they require a running
# llama.cpp server. Use `ruby bin/verify_llm.rb` in CI pre-flight instead.

RSpec.configure do |config|
  # Bypass WebMock + VCR for :live tagged examples so real HTTP is allowed.
  config.around(:each, :live) do |example|
    WebMock.allow_net_connect!
    VCR.turned_off { example.run }
  ensure
    WebMock.disable_net_connect!
  end

  # Skip :live specs unless explicitly opted in.
  config.filter_run_excluding live: true unless ENV['RUN_LIVE_SPECS'] == '1' || RSpec.configuration.filter_manager.inclusions.rules[:live]
end
