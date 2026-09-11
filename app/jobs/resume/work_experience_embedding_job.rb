# frozen_string_literal: true

# Mirrors Resume::EmbeddingJob -- same queue, same idempotency shape. Split
# per-experience rather than per-profile so adding one project entry doesn't
# re-embed a whole career history.
class Resume::WorkExperienceEmbeddingJob < ApplicationJob
  queue_as :heavy
  heavyweight!
  idempotent! ->(experience_id) { "work_experience_embedding/#{experience_id}" }

  def perform(experience_id)
    experience = WorkExperience.find(experience_id)
    embedding = VectorIntelligence.embed(experience.embeddable_text)
    return if embedding.blank?

    experience.update!(embedding: embedding)
  end
end
