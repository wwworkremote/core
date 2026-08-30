# frozen_string_literal: true

# VCR's `config.ignore_localhost = true` (spec/support/vcr.rb) exists so
# Capybara/Cuprite can reach the test server -- but it also turns every
# *unstubbed* request to the local llama.cpp servers (:11500 chat, :11501
# embeddings) into a real network call instead of a loud
# WebMock::NetConnectNotAllowedError. When the real server is up, an
# unstubbed RubyLLM model probe returns a model list without the test
# fixture id and surfaces as `RubyLLM::ModelNotFoundError` -- an
# order-dependent flake in pre-commit / CI runs.
#
# This re-arms the safety net for just those two ports: a non-:live example
# that makes an unstubbed local-inference call fails loudly. An example's
# own `stub_request` is registered later and still wins for requests it
# matches.
LOCAL_INFERENCE_URL = %r{\Ahttps?://(localhost|127\.0\.0\.1):1150[01]/}

RSpec.configure do |config|
  config.before do |example|
    next if example.metadata[:live]

    stub_request(:any, LOCAL_INFERENCE_URL).to_raise(
      "Unstubbed local-inference call (:11500/:11501) -- this example is not " \
      "hermetic. Stub the exact request, or tag it `:live`."
    )
  end
end
