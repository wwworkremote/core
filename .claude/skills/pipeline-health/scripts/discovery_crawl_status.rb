# frozen_string_literal: true

#
# TASK-74: per-board breakdown of the crawl-based discovery pipeline
# (Scraper::CrawlDiscoveryJob -> DiscoveryLink -> Scraper::DiscoveryConsumerJob
# -> JobPosting). Errors in this pipeline are caught and stored on the
# DiscoveryLink row itself (see DiscoveryConsumerJob#process_link), so they
# never reach SolidQueue::FailedExecution -- check_pipeline_health.rb's
# "Failed jobs by class" section is structurally blind to this class of bug.
# This script exists because that ambiguity (silent no-op vs. genuinely
# nothing new) took a full manual DB investigation to resolve once; it
# shouldn't take one again for the next board or the next regression. Run:
#   bin/rails runner .claude/skills/pipeline-health/scripts/discovery_crawl_status.rb
#
# Classifies each crawl-based source as:
#   CRAWL-DEAD   -- zero DiscoveryLinks ever: the crawl step itself finds
#                   nothing (stale selector/URL, site layout changed).
#                   Needs its own per-source investigation.
#   BACKED UP    -- links exist but pending ones are older than 1h: the
#                   consumer isn't draining them (scheduling/code bug).
#   HEALTHY      -- links exist and nothing pending older than 1h.
# Makes no writes.

def section(title)
  puts "\n=== #{title} ==="
  yield
end

crawl_slugs = Ingestion::AdapterRegistry.all
                                        .select { |_, cfg| cfg[:class] == Scraper::CrawlDiscoveryJob }
                                        .keys

section("Crawl-based sources (Scraper::CrawlDiscoveryJob)") do
  crawl_slugs.each do |slug|
    source = JobBoards::Source.find_by(slug: slug)
    links = DiscoveryLink.where(board_name: slug)
    by_status = links.group(:status).count
    oldest_pending = links.where(status: "pending").minimum(:created_at)

    verdict =
      if links.none?
        "CRAWL-DEAD (no links ever discovered)"
      elsif oldest_pending && oldest_pending < 1.hour.ago
        "BACKED UP (oldest pending link: #{oldest_pending})"
      else
        "HEALTHY"
      end

    puts "\n#{slug} -- #{verdict}"
    puts "  last_synced_at:    #{source&.last_synced_at || 'never'}"
    puts "  last_ingested_at:  #{source&.last_ingested_at || 'never'}"
    puts "  discovery_links:   #{by_status.presence || 'none'}"
    puts "  max link created:  #{links.maximum(:created_at) || 'n/a'}"
  end
end
