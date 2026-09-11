# frozen_string_literal: true

require "digest"

class HackerNews::Backfill
  BASE_URL = "https://hn.algolia.com/api/v1/search_by_date"

  def call(before_timestamp: Time.zone.now.to_i)
    source = JobBoards::Source.find_or_create_by!(slug: "hackernews", name: "Hacker News")
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)

    response = connection(before_timestamp).get
    hits = JSON.parse(response.body)["hits"]
    store_hits(hits, source, query)
  end

  private

  def connection(before_timestamp)
    Faraday.new(url: BASE_URL) do |f|
      f.params["tags"] = "job"
      f.params["numericFilters"] = "created_at_i<#{before_timestamp}"
      f.params["hitsPerPage"] = 100
    end
  end

  def store_hits(hits, source, query)
    hits.each { |hit| store_hit(hit, source, query) }
  end

  # One cohesive find_or_create_by! call -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def store_hit(hit, source, query)
    signature = Digest::SHA256.hexdigest("hn-#{hit['objectID']}")

    JobBoards::Document.find_or_create_by!(signature:) do |doc|
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = hit_attributes(hit).to_json
    end
  end

  # Transform Algolia format to match Firebase format as much as possible for the Syncer
  # rubocop:disable-next Metrics/MethodLength
  def hit_attributes(hit)
    {
      id: hit["objectID"],
      title: hit["title"],
      url: hit["url"],
      text: hit["comment_text"] || hit["story_text"],
      by: hit["author"],
      time: hit["created_at_i"],
      type: "job"
    }
  end
end
