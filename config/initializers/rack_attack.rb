# frozen_string_literal: true

# Rate limiting for API and ingestion endpoints.
# Deliberately NOT Rails.cache (Solid Cache) -- a dedicated in-process
# MemoryStore keeps throttle counters off the DB-backed cache so a slow
# Solid Cache write can't add latency to every request. Disabled entirely
# in test (config/environments/test.rb) since this store is process-global
# and nothing in the RSpec suite resets it between examples -- see TASK-110.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

# Throttle API requests by IP (60 requests per minute)
Rack::Attack.throttle("api/ip", limit: 60, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api/")
end

# Throttle login attempts (5 per 20 seconds)
Rack::Attack.throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == "/" && req.get? && req.env["HTTP_AUTHORIZATION"].present?
end

# Block suspicious requests
Rack::Attack.blocklist("block bad paths") do |req|
  req.path.match?(%r{\A/(wp-admin|phpmyadmin|\.env)}i)
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  payload = event.payload
  Rails.logger.warn "[RackAttack] Throttled #{payload[:request].ip} on #{payload[:request].path}"
end
