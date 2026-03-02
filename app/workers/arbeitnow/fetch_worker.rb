# frozen_string_literal: true

module Arbeitnow
  class FetchWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      Arbeitnow::Fetcher.new.call
    end
  end
end
