# frozen_string_literal: true

module Remotive
  class FetchWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      Remotive::Fetcher.new.call
    end
  end
end
