# frozen_string_literal: true

require "mission_control/jobs"

# Mission Control - Jobs Basic Authentication
# Same credentials as ApplicationController's authenticate_admin
MissionControl::Jobs.tap do |config|
  config.http_basic_auth_enabled = true
  config.http_basic_auth_user = ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")
  config.http_basic_auth_password = ENV.fetch("ADMIN_PASSWORD", "password")
end
