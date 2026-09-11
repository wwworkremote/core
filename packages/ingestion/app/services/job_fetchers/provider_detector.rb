# frozen_string_literal: true

# Maps a job posting URL to the provider key used to select
# JobFetchers::CanonicalJobExtractor::Selectors and other per-provider
# behavior. Shared by every caller that previously carried its own
# ad hoc domain => provider table (ContentEnrichmentJob,
# JobPostingEnrichment::DescriptionResolver), which had drifted out of
# sync with each other and with the selector keys themselves.
module JobFetchers::ProviderDetector
  DOMAINS = {
    "linkedin.com" => "linkedin",
    "indeed.com" => "indeed",
    "adzuna.com" => "adzuna",
    "glassdoor.com" => "glassdoor",
    "dice.com" => "dice",
    "greenhouse.io" => "greenhouse",
    "lever.co" => "lever",
    "workday.com" => "workday",
    "myworkdayjobs.com" => "workday",
    "ashby.com" => "ashby",
    "ashbyhq.com" => "ashby",
    "smartrecruiters.com" => "smartrecruiters",
    "wellfound.com" => "wellfound",
    "weworkremotely.com" => "wwr",
    "remoteok.com" => "remoteok"
  }.freeze

  def self.call(url)
    return "generic" if url.blank?

    url_lower = url.to_s.downcase
    DOMAINS.find { |domain, _| url_lower.include?(domain) }&.last || "generic"
  end
end
