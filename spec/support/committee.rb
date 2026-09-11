# frozen_string_literal: true

# Validates real request specs against docs/architecture/openapi.yaml --
# the extension's actual contract, not just what a controller happens to
# permit/render. Opt-in per spec via `include Committee::Test::Methods` +
# `assert_schema_conform`, not global: the spec's schema only covers the
# extension-facing `namespace :api` block, not the rest of the app.
require "committee"

module CommitteeSupport
  def committee_options
    @committee_options ||= {
      schema_path: Rails.root.join("docs/architecture/openapi.yaml").to_s,
      prefix: "/api",
      strict_reference_validation: true
    }
  end

  # Committee::Test::Methods is Rack::Test-flavored (last_request/last_response);
  # bridge to the ActionDispatch objects RSpec request specs actually expose.
  def request_object
    request
  end

  def response_data
    [response.status, response.headers, response.body]
  end
end

RSpec.configure do |config|
  config.include Committee::Test::Methods, type: :request
  config.include CommitteeSupport, type: :request
end
