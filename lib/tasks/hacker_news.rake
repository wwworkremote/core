# frozen_string_literal: true

require 'socket'

namespace :hacker_news do
  desc 'Fetch latest jobstories from HackerNews'
  task fetch_latest_jobstories: :environment do
    HackerNews::FetchLatestJobstories.new.call if Socket.gethostname.casecmp?('node01')
  end
end
