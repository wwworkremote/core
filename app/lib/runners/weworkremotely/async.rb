# frozen_string_literal: true

module Runners
  module WeWorkRemotely
    class Async
      sidekiq_options queue: :runners

      include Sidekiq::Worker

      def perform(term = nil)
        term = 'sidekiq' if term.blank?
        Rails.logger = Rails.logger.child(term: term, entrypoint: self.class.name)
        Runners::WeWorkRemotely.run(term: term)
      end
    end
  end
end
