# frozen_string_literal: true

module Runners
  module StackOverflow
    class Async
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker
      sidekiq_options queue: :stackoverflow_runners
      sidekiq_throttled(concurrency: { limit: 1 }, threshold: { limit: 1, period: 30.minutes })

      def perform(term = nil)
        term = 'sidekiq' if term.blank?
        Runners::StackOverflow.run(term: term)
      end
    end
  end
end
