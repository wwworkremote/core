# frozen_string_literal: true

module Runners
  module Nexxt
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      sidekiq_options queue: :nexxt_runners

      sidekiq_throttle(
        concurrency: {
          limit: 1,
          key_suffix: ->(term) { term }
        },
        threshold: {
          limit: 1,
          period: 15.minutes,
          key_suffix: ->(term) { term }
        }
      )

      def perform(term:)
        Runners::Nexxt.run(term: term)
      end
    end
  end
end
