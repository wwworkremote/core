# frozen_string_literal: true

module Runners
  module AuthenticJobs
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      sidekiq_options queue: :authenticjobs_runners
      sidekiq_throttle(concurrency: { limit: 1 }, threshold: { limit: 1, period: 15.minutes })

      def perform(term)
        Runners::Monster.run(term:)
      end
    end
  end
end
