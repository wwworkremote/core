# frozen_string_literal: true

class HackerNews::FetchLatestJobstories
  include ApiGuard

  def call(force: false)
    with_api_guard("hackernews", cooldown: 15.minutes, force:) do |source|
      dispatch_jobstories(source)
    end
  end

  private

  def dispatch_jobstories(source)
    query = JobBoards::Query.find_or_create_by!(source_id: source.id)
    jobstory_ids = fetch_jobstory_ids
    log_jobstory_ids(jobstory_ids)

    HackerNews::FetchJobstories.new(jobstory_ids: jobstory_ids, source_id: source.id, query_id: query.id).call
  end

  def log_jobstory_ids(jobstory_ids)
    Rails.logger.info { "#{self.class.name}#call ==>> jobstory_ids:#{jobstory_ids.join(',')}" }
  end

  def fetch_jobstory_ids
    conn = Faraday.new(
      url: "https://hacker-news.firebaseio.com",
      headers: { "Content-Type" => "application/json" }
    )
    Oj.load(conn.get("/v0/jobstories.json").body, symbolize_names: true)
  end
end
