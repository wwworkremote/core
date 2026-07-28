# frozen_string_literal: true

# Fallback crawl targets used by DataAcquisitionManager.run_crawler when a
# board has no BoardQuery rows of its own yet.
module DataAcquisitionManager::CrawlDefaults
  URLS = {
    "cord" => "https://cord.com/search/jobs/software-developer",
    "linkedin" => "https://www.linkedin.com/jobs/search/?keywords=Software%20Engineer",
    "indeed" => "https://www.indeed.com/jobs?q=Software%20Engineer",
    "dice" => "https://www.dice.com/jobs?q=Staff%20Engineer&location=Remote",
    "remoteok" => "https://remoteok.com/remote-ruby-jobs",
    "wwr" => "https://weworkremotely.com/categories/remote-programming-jobs"
  }.freeze

  SELECTOR = 'a[href*="/job/"]'
end
