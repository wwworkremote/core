# frozen_string_literal: true

class HackerNews::FetchJobstoryJob < ApplicationJob
  include ApiGuard

  ITEM_URL = "https://hacker-news.firebaseio.com/v0/item/%<id>s.json"

  queue_as :light
  lightweight!

  def perform(jobstory_id, source_id = nil, query_id = nil)
    return if source_locked?("hackernews")

    data = fetch_job_data(jobstory_id)
    data && process(jobstory_id, data, source_id, query_id)
  end

  private

  def process(jobstory_id, data, source_id, query_id)
    ids = resolve_ids(source_id, query_id)
    return unless ids

    persist_document(jobstory_id, data, ids)
    # Trigger sync after fetch
    JobBoards::Syncer.new.call
  end

  def fetch_job_data(jobstory_id)
    response = fetch_response(jobstory_id)
    return nil unless response

    parse_job(response.body)
  end

  def fetch_response(jobstory_id)
    response = JobBoards::Client.new("hackernews").get(format(ITEM_URL, id: jobstory_id))
    response if response && response.status == 200
  end

  def parse_job(body)
    data = Oj.load(body, symbolize_names: true)
    data if data && data[:type] == "job"
  end

  def resolve_ids(source_id, query_id)
    source_id ||= JobBoards::Source.find_by(slug: "hackernews")&.id
    query_id ||= JobBoards::Query.find_by(source_id: source_id)&.id
    [source_id, query_id] if source_id && query_id
  end

  def persist_document(jobstory_id, data, ids)
    signature = Digest::SHA256.hexdigest("hn-#{jobstory_id}")
    doc = JobBoards::Document.find_or_initialize_by(signature: signature)
    return unless doc.new_record?

    save_document(doc, signature, data, ids)
  end

  def save_document(doc, signature, data, ids)
    source_id, query_id = ids
    doc.assign_attributes(source_id: source_id, job_boards_query_id: query_id, document: data.to_json)
    return if doc.save

    Rails.logger.error "[HackerNews::FetchJobstoryJob] Failed to save document #{signature}: " \
                       "#{doc.errors.full_messages.join(', ')}"
  end
end
