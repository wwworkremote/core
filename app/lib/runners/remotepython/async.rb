# frozen_string_literal: true

module Runners
  module RemotePython
    class Async
      include Sidekiq::Worker
      sidekiq_options queue: :runners

      def perform(term = nil)
        term = 'sidekiq' if term.blank?
        Rails.logger = Rails.logger.child(term: term, entrypoint: self.class.name)
        Runners::RemotePython.run(term: term)
      end
    end
  end
end
