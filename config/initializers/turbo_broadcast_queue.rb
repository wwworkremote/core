# frozen_string_literal: true

# Turbo's built-in broadcast job defaults to the same "default" queue as
# heavyweight LLM/geocoding/Playwright jobs. With only a handful of default-queue
# threads, thousands of cheap high-frequency UI-push jobs (2x per JobPosting save,
# plus Source/DiscoveryLink) queue up behind slow work with zero isolation --
# this produced a 4,700+ job backlog of stale broadcasts before cleanup on
# 2026-07-27 (TASK-21). Give them their own queue so they can never head-of-line
# block behind heavy work again.
Rails.application.config.to_prepare do
  Turbo::Streams::ActionBroadcastJob.queue_as :broadcasts
end
