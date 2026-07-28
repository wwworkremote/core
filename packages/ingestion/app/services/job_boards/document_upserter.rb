# frozen_string_literal: true

# Upserts one JobBoards::Document from raw provider job data, tracking which
# search terms matched it across repeated fetches. Lever::Fetcher and
# Greenhouse::Fetcher had this exact logic duplicated (only the match field
# and slug key name differed) -- consolidated here as the one shared
# collaborator both call, per this codebase's AOP convention of extracting
# cross-cutting logic once rather than per call site.
class JobBoards::DocumentUpserter
  Context = Struct.new(:provider, :slug, :slug_key, :term, :match_field, :source_id, :query_id, keyword_init: true)

  def self.call(context, job_data)
    new(context, job_data).call
  end

  def initialize(context, job_data)
    @context = context
    @job_data = job_data
  end

  def call
    return if term_mismatch?

    document.document = merged_payload.to_json
    document.save!
  end

  private

  def term_mismatch?
    @context.term.present? && @job_data[@context.match_field].to_s.downcase.exclude?(@context.term.downcase)
  end

  def document
    @document ||= JobBoards::Document.find_or_initialize_by(signature: signature).tap do |doc|
      doc.source_id = @context.source_id
      doc.job_boards_query_id = @context.query_id
    end
  end

  def signature
    "#{@context.provider}-#{@context.slug}-#{@job_data['id']}"
  end

  def merged_payload
    payload = existing_or_new_payload
    track_term(payload)
    payload[@context.slug_key] = @context.slug
    payload
  end

  def existing_or_new_payload
    document.document.present? ? JSON.parse(document.document) : @job_data
  end

  def track_term(payload)
    payload["found_by_terms"] ||= []
    return if @context.term.blank? || payload["found_by_terms"].include?(@context.term)

    payload["found_by_terms"] << @context.term
  end
end
