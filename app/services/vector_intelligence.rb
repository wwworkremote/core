# frozen_string_literal: true

module VectorIntelligence
  # Centralized interface for embedding and semantic search across the system.

  def self.embed(text)
    # Delegates to the low-level embedder, but provides a stable system-wide seam.
    JobBoards::Embedder.embed_text(text)
  end

  # Ranks a collection of target records based on their similarity to a source.
  # @param source [ActiveRecord::Base] The record providing the reference embedding (e.g., a Resume).
  # @param target_class [Class] The class to search within (e.g., JobPosting).
  # @param limit [Integer] Max results to return.
  # @return [ActiveRecord::Relation]
  def self.rank(source:, target_class:, limit: 10)
    return target_class.none unless source.respond_to?(:embedding) && source.embedding.present?

    target_class.nearest_neighbors(:embedding, source.embedding, distance: "cosine").limit(limit)
  end

  # Generic search for any class supporting embeddings.
  def self.search(query_text, target_class:, limit: 10)
    embedding = embed(query_text)
    return target_class.none if embedding.blank?

    target_class.nearest_neighbors(:embedding, embedding, distance: "cosine").limit(limit)
  end
end
