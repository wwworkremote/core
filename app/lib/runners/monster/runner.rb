# frozen_string_literal: true

module Runners
  module Monster
    class Runner
      attr_reader :term, :runner_instance_uuid, :tag

      def initialize(term:)
        @tag = 'exe/monster'
        @runner_instance_uuid = Druuid.gen.to_s.freeze
        @term = term.freeze
      end

      def before
        Rails.logger.tagged(runner_instance_uuid) do
          Rails.logger.info { "START #{tag} #{term} pid:#{Process.pid}" }
        end
      end

      def after
        Rails.logger.tagged(runner_instance_uuid) do
          Rails.logger.info { "END #{tag} #{term} pid:#{Process.pid}" }
        end
      end

      def handle_error(err)
        Rails.logger.tagged(runner_instance_uuid) do
          Rails.logger.error { "ERROR #{tag} #{term} pid:#{Process.pid} -- #{err.class}: #{err.message}" }
        end
      end

      def call
        before

        Pullers::Monster.pull(term: term)
      rescue StandardError => e
        binding.pry
        put
        handle_error(e)
      ensure
        after
      end
    end
  end
end
