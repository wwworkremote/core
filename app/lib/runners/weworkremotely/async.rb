# frozen_string_literal: true

module Runners
  module WeWorkRemotely
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      sidekiq_options queue: :weworkremotely_runners

      sidekiq_throttle(
        concurrency: {
          limit: 1,
          key_suffix: ->(term:) { term.to_s }
        },
        threshold: {
          limit: 1,
          period: 15.minutes,
          key_suffix: ->(term:) { term.to_s }
        }
      )

      def perform(term: 'sidekiq')
        Runners::WeWorkRemotely.run(term: term)
      end
    end
  end
end
