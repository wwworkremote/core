# frozen_string_literal: true

class Quality::InsightEmbeddingJob < ApplicationJob
  queue_as :low
  mediumweight!

  def perform(insight_id = nil)
    if insight_id
      generate_single(insight_id)
    else
      generate_all_pending
    end
  end

  private

  def generate_single(id)
    insight = SystemInsight.find_by(id: id)
    return unless insight
    return if insight.embedding.present?

    text = construct_text(insight)
    embedding = JobBoards::Embedder.embed_text(text)

    if embedding
      insight.update_column(:embedding, embedding)
    else
      Rails.logger.error "[InsightEmbeddingJob] Failed to generate embedding for Insight #{id}"
    end
  end

  def generate_all_pending
    SystemInsight.where(embedding: nil).find_each do |insight|
      # Enqueue individual jobs for better concurrency
      self.class.perform_later(insight.id)
    end
  end

  def construct_text(insight)
    [
      "Tool: #{insight.tool}",
      "File: #{insight.file_path}",
      "Severity: #{insight.severity}",
      "Message: #{insight.message}"
    ].join("\n")
  end
end
