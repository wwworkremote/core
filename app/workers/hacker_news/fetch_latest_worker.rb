# frozen_string_literal: true

module HackerNews
  class FetchLatestWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      HackerNews::FetchLatestJobstories.new.call
    end
  end
end
