# frozen_string_literal: true

module Runners
  module Monster
    class Runner
      attr_reader :term, :context

      def initialize(term:)
        @term = term.strip.freeze
        @context = Rails.configuration.x.context.merge(term: term)
      end

      def call
        Rails.logger.info(context.merge(msg: 'Start'))

        Pullers::Monster.pull(term: term)
      rescue StandardError => e
        Rails.logger.error(e.message, context)
        Rails.logger.debug { e }
      ensure
        Rails.logger.info(context.merge(msg: 'End'))
      end
    end
  end
end
