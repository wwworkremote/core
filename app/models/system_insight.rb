# frozen_string_literal: true

class SystemInsight < ApplicationRecord
  has_neighbors :embedding # For vector similarity searches

  enum :tool, {
    rubocop: 0,
    reek: 1,
    brakeman: 2,
    rails_best_practices: 3,
    flay: 4,
    packwerk: 5
  }

  enum :severity, {
    advisory: 0,
    warning: 1,
    critical: 2
  }

  validates :message, presence: true
  validates :tool, presence: true

  scope :active, -> { where(active: true) }

  after_create_commit :enqueue_embedding

  def self.for_file(path)
    where(file_path: path, active: true)
  end

  private

  def enqueue_embedding
    Quality::InsightEmbeddingJob.perform_later(id)
  end
end
