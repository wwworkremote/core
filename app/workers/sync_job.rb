# frozen_string_literal: true

class SyncJob
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform
    JobBoards::Syncer.new.call
  end
end
