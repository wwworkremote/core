# frozen_string_literal: true

class Resume::EmbeddingJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(profile_id) { "embedding/#{profile_id}" }

  def perform(profile_id)
    profile = CareerProfile.find(profile_id)
    Resume::ProfileEmbedder.new(profile).call
  end
end
