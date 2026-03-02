# frozen_string_literal: true

module Wwr
  class FetchWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform
      Wwr::Fetcher.new.call
    end
  end
end
