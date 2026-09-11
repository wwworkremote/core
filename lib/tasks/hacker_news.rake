# frozen_string_literal: true

namespace :hacker_news do
  desc "Fetch latest jobstories from HackerNews"
  task fetch_latest_jobstories: :environment do
    HackerNews::FetchLatestJobstories.new.call
  end
end
