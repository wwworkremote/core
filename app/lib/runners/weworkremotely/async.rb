# frozen_string_literal: true

module Runners
  module WeWorkRemotely
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker
      sidekiq_options queue: :weworkremotely_runners
      sidekiq_throttle(concurrency: { limit: 2 }, threshold: { limit: 2, period: 15.minutes })

      def perform(term = nil)
        term = 'sidekiq' if term.blank?
        Runners::WeWorkRemotely.run(term: term)
      end
    end
  end
end
