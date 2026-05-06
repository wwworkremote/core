# frozen_string_literal: true

# Register all ingestion sources with the Ingestion::AdapterRegistry.
# This centralizes configuration and allows the DataAcquisitionManager to stay deep and focused on orchestration.

Rails.application.config.to_prepare do
  # API Fetchers
  Ingestion::AdapterRegistry.register("adzuna", Adzuna::Fetcher, name: "Adzuna", type: "API", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("remotive", Remotive::Fetcher, name: "Remotive", type: "API", cooldown: 1.hour)
  Ingestion::AdapterRegistry.register("hackernews", HackerNews::FetchLatestJobstories, name: "HackerNews", type: "API", cooldown: 15.minutes)

  # Feed Fetchers
  Ingestion::AdapterRegistry.register("arbeitnow", Arbeitnow::Fetcher, name: "Arbeitnow", type: "Feed", cooldown: 2.hours)
  Ingestion::AdapterRegistry.register("jobicy", Jobicy::Fetcher, name: "Jobicy", type: "Feed", cooldown: 4.hours)

  # Scraper Fetchers (Standard)
  Ingestion::AdapterRegistry.register("greenhouse", Greenhouse::Fetcher, name: "Greenhouse", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("lever", Lever::Fetcher, name: "Lever", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("wwr", Wwr::Fetcher, name: "Wwr", type: "Scraper", cooldown: 30.minutes)
  Ingestion::AdapterRegistry.register("yc", Yc::Scraper, name: "YC", type: "Scraper", cooldown: 4.hours)

  # Crawler-based Scrapers
  Ingestion::AdapterRegistry.register("cord", Scraper::CrawlDiscoveryJob, name: "Cord", type: "Scraper", cooldown: 2.hours)
  Ingestion::AdapterRegistry.register("linkedin", Scraper::LinkedIn::ApiClient, name: "LinkedIn", type: "Scraper", cooldown: 1.hour)
  Ingestion::AdapterRegistry.register("indeed", Scraper::Indeed::ApiClient, name: "Indeed", type: "Scraper", cooldown: 1.hour)
  Ingestion::AdapterRegistry.register("dice", Scraper::Dice::ApiClient, name: "Dice", type: "Scraper", cooldown: 2.hours)
  Ingestion::AdapterRegistry.register("glassdoor", Scraper::Glassdoor::ApiClient, name: "Glassdoor", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("builtin", Scraper::CrawlDiscoveryJob, name: "BuiltIn", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("remoteio", Scraper::CrawlDiscoveryJob, name: "Remote IO", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("remoteok", Scraper::CrawlDiscoveryJob, name: "RemoteOK", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("flexjobs", Scraper::CrawlDiscoveryJob, name: "FlexJobs", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("bestjobs", Scraper::CrawlDiscoveryJob, name: "BestJobs", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("echojobs", Scraper::CrawlDiscoveryJob, name: "EchoJobs", type: "Scraper", cooldown: 4.hours)
  Ingestion::AdapterRegistry.register("roberthalf", Scraper::CrawlDiscoveryJob, name: "Robert Half", type: "Scraper", cooldown: 4.hours)

  # Email Fetchers
  Ingestion::AdapterRegistry.register("email_indeed", EmailImportJob, name: "Email (Indeed)", type: "Email", cooldown: 1.hour)
  Ingestion::AdapterRegistry.register("email_adzuna", EmailImportJob, name: "Email (Adzuna)", type: "Email", cooldown: 1.hour)
  Ingestion::AdapterRegistry.register("email_linkedin", EmailImportJob, name: "Email (LinkedIn)", type: "Email", cooldown: 1.hour)
end
