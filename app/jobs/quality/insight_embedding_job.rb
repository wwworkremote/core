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

    embedding = JobBoards::Embedder.embed_text(construct_text(insight))
    apply_embedding(insight, embedding)
  end

  def apply_embedding(insight, embedding)
    if embedding
      insight.update!(embedding: embedding)
    else
      Rails.logger.error "[InsightEmbeddingJob] Failed to generate embedding for Insight #{insight.id}"
    end
  end

  def generate_all_pending
    SystemInsight.where(embedding: nil).find_each do |insight|
      # Enqueue individual jobs for better concurrency
      self.class.perform_later(insight.id)
    end
  end

  def construct_text(insight)
    text_lines(insight).join("\n")
  end

  def text_lines(insight)
    ["Tool: #{insight.tool}", "File: #{insight.file_path}"] +
      ["Severity: #{insight.severity}", "Message: #{insight.message}"]
  end
end
