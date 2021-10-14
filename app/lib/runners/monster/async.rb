# frozen_string_literal: true

module Runners
  module Monster
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker
      sidekiq_options queue: :monster_runners
      sidekiq_throttle(concurrency: { limit: 2 }, threshold: { limit: 2, period: 15.minutes })

      def perform(term = nil)
        term = 'sidekiq' if term.blank?
        Runners::Monster.run(term: term)
      end
    end
  end
end
