# frozen_string_literal: true

module JobBoards
  class Auditor
    def initialize(options = {})
      @fix = options.fetch(:fix, true)
      @limit = options.fetch(:limit, 100)
    end

    def call
      stats = {
        missing_postings: 0,
        missing_category: 0,
        missing_embedding: 0,
        missing_geocoding: 0,
        fixed: 0
      }

      # 1. Check for documents without postings
      JobBoards::Document.find_each do |doc|
        unless JobPosting.exists?(signature: doc.signature)
          stats[:missing_postings] += 1
          if @fix && stats[:fixed] < @limit
            JobBoards::Syncer.new.send(:sync_document, doc)
            stats[:fixed] += 1
          end
        end
      end

      # 2. Check for postings without AI category
      JobPosting.where("data->'ai_category' IS NULL").find_each do |jp|
        stats[:missing_category] += 1
        if @fix && stats[:fixed] < @limit
          JobBoards::Categorizer.new(jp).call
          stats[:fixed] += 1
        end
      end

      # 3. Check for postings without embeddings
      JobPosting.where(embedding: nil).find_each do |jp|
        stats[:missing_embedding] += 1
        if @fix && stats[:fixed] < @limit
          JobBoards::Embedder.new(jp).call
          stats[:fixed] += 1
        end
      end

      # 4. Check for postings without geocoding
      JobPosting.where(latitude: nil).where.not(location: nil).find_each do |jp|
        stats[:missing_geocoding] += 1
        if @fix && stats[:fixed] < @limit
          jp.enqueue_geocoding
          stats[:fixed] += 1
        end
      end

      stats
    end
  end
end
