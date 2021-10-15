# frozen_string_literal: true

module Runners
  module RemotePython
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      sidekiq_options queue: :remotepython_runners

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
        Runners::RemotePython.run(term: term)
      end
    end
  end
end
