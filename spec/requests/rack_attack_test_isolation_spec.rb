# frozen_string_literal: true

require "rails_helper"

# Regression spec for TASK-110: Rack::Attack's throttle counters live in a
# bare, dedicated ActiveSupport::Cache::MemoryStore (config/initializers/
# rack_attack.rb), NOT Rails.cache -- so the `Rails.cache.clear` that
# rails_helper runs before every example never resets them. That store is
# also process-global (one instance for the life of the whole `rspec`
# invocation), so throttle counts accumulate across every request spec that
# hits an /api/ path from the same test-client IP, and can trip mid-suite
# regardless of which spec happens to be the 61st to touch /api/ that
# minute -- see TASK-110's api/v0/application_* cluster and leads_spec.rb
# failures, both order-dependent and both invisible in isolation.
RSpec.describe "Rack::Attack in the test environment" do
  it "does not throttle a burst of /api/ requests from the same example" do
    62.times { get "/api/v0/geo" }

    expect(response).not_to have_http_status(:too_many_requests)
  end
end
