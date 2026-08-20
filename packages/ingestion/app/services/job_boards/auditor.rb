# frozen_string_literal: true

class JobBoards::Auditor
  def initialize(options = {})
    @fix = options.fetch(:fix, true)
    @limit = options.fetch(:limit, 100)
    @stats = { missing_postings: 0, missing_category: 0, missing_embedding: 0, missing_geocoding: 0, fixed: 0,
               low_quality_fixed: 0 }
  end

  AUDITS = %i[audit_missing_postings audit_missing_category audit_missing_embedding audit_missing_geocoding
              audit_low_quality].freeze

  def call
    AUDITS.each { |audit| send(audit) }
    @stats
  end

  private

  def audit_missing_postings
    JobBoards::Document.find_each do |doc|
      next if JobPosting.exists?(signature: doc.signature)

      @stats[:missing_postings] += 1
      apply_fix { JobBoards::Syncer.new.send(:sync_document, doc) }
    end
  end

  def audit_missing_category
    JobPosting.where("data->'ai_category' IS NULL").find_each do |jp|
      @stats[:missing_category] += 1
      apply_fix { JobBoards::Categorizer.new(jp).call }
    end
  end

  def audit_missing_embedding
    JobPosting.where(embedding: nil).find_each do |jp|
      @stats[:missing_embedding] += 1
      apply_fix { JobBoards::Embedder.new(jp).call }
    end
  end

  def audit_missing_geocoding
    JobPosting.where(latitude: nil).where.not(location: nil).find_each do |jp|
      @stats[:missing_geocoding] += 1
      apply_fix { jp.enqueue_geocoding }
    end
  end

  # Borrows the :missing_category counter rather than adding a new stat key,
  # matching the original auditor's reporting shape.
  def audit_low_quality
    JobPosting.where.not(status: "ignored").find_each do |jp|
      next if JobBoards::QualityFilter.new(jp).useful?

      @stats[:missing_category] += 1
      apply_low_quality_fix { jp.ignore! } if jp.may_ignore?
    end
  end

  def apply_fix
    return unless @fix && @stats[:fixed] < @limit

    yield
    @stats[:fixed] += 1
  end

  # Own budget, separate from the other four audits' shared @stats[:fixed]
  # counter -- otherwise a large missing_postings/missing_category backlog
  # starves this correctness-enforcing sweep every run (see TASK-73).
  def apply_low_quality_fix
    return unless @fix && @stats[:low_quality_fixed] < @limit

    yield
    @stats[:low_quality_fixed] += 1
    @stats[:fixed] += 1
  end
end
