# frozen_string_literal: true

require "digest"
require "feedjira"

class Wwr::Fetcher
  include ApiGuard

  RSS_URL = "https://weworkremotely.com/remote-jobs.rss"

  def call(force: false)
    with_api_guard("wwr", cooldown: 30.minutes, force:) do |source|
      fetch_and_store(source)
    end
  end

  private

  def fetch_and_store(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    response = JobBoards::Client.new("wwr").get(RSS_URL)
    return unless response && response.status == 200

    store_entries(Feedjira.parse(response.body).entries, source, query)
  end

  def store_entries(entries, source, query)
    entries.each { |entry| store_entry(entry, source, query) }
  end

  # One cohesive find_or_create_by! call -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def store_entry(entry, source, query)
    signature = Digest::SHA256.hexdigest("wwr-#{entry.entry_id}")

    JobBoards::Document.find_or_create_by!(signature:) do |doc|
      doc.source_id = source.id
      doc.job_boards_query_id = query.id
      doc.document = entry_attributes(entry).to_json
    end
  end

  # rubocop:disable-next Metrics/MethodLength
  def entry_attributes(entry)
    {
      title: entry.title,
      url: entry.url,
      entry_id: entry.entry_id,
      published: entry.published,
      content: entry.content,
      summary: entry.summary
    }
  end
end
