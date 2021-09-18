# frozen_string_literal: true

module Runners
  module StackOverflow
    class Runner
      attr_reader :term, :runner_instance_uuid, :tag

      def initialize(term:)
        @tag = 'exe/stackoverflow'
        @runner_instance_uuid = Druuid.gen.to_s.freeze
        @term = term.freeze
      end

      def action
        Pullers::StackOverflow.jobs(term: term)
      end

      def before
        # logger.tagged(runner_instance_uuid) { logger.info { "START #{tag} #{term} pid:#{Process.pid}" } }
      end

      def after
        # logger.tagged(runner_instance_uuid) { logger.info { "END #{tag} #{term} pid:#{Process.pid}" } }
      end

      def error(err)
        # logger.tagged(runner_instance_uuid) { logger.error { "ERROR #{tag} #{term} pid:#{Process.pid} -- #{err.class}: #{err.message}" } }
      end

      def call
        before
        action
      rescue StandardError => e
        error(e)
      ensure
        after
      end
    end
  end
end
