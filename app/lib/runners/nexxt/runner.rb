# frozen_string_literal: true

module Runners
  module Nexxt
    class Runner
      attr_reader :term

      def initialize(term:)
        @term = term.strip.freeze
      end

      def call
        Rails.logger.info('Begin')

        Pullers::Nexxt.pull(term: term)

        Rails.logger.info('Complete')
      rescue StandardError => e
        Rails.logger.error(e.message)
        Rails.logger.debug { e }
      ensure
        Rails.logger.info('End')
      end
    end
  end
end
