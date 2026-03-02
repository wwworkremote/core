# frozen_string_literal: true

module Workable
  class FetchWorker
    include Sidekiq::Worker
    sidekiq_options queue: :default

    def perform(subdomain, token)
      Workable::Fetcher.new(subdomain: subdomain, token: token).call
    end
  end
end
