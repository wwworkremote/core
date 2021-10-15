# frozen_string_literal: true

module Runners
  module Indeed
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker
      sidekiq_options queue: :indeed_runners
      sidekiq_throttle(concurrency: { limit: 1 }, threshold: { limit: 1, period: 15.minutes })

      def perform(term: 'sidekiq')
        Runners::Indeed.run(term: term)
      end
    end
  end
end
