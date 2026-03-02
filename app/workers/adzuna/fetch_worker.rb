# frozen_string_literal: true

module Adzuna
  class FetchWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      Adzuna::Fetcher.new.call
    end
  end
end
