# frozen_string_literal: true

# Rate limiting for API and ingestion endpoints.
# rack-attack uses Rails.cache as its backing store (Solid Cache).
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
