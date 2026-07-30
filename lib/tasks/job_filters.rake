# frozen_string_literal: true

namespace :job_filters do
  desc "Disable ingestion and purge existing postings for any company matching the big-tech blocklist"
  task backfill_big_tech: :environment do
    companies = Company.big_tech.where(ingestion_enabled: true)
    puts "Disabling ingestion for #{companies.count} existing big-tech compan(y/ies)..."
    companies.find_each do |company|
      # Matches Company#disable_ingestion!'s own exclusion -- purge can't
      # transition from :expired, and expired postings are already hidden
      # from every default listing.
      count = company.job_postings.where.not(status: %w[purged expired]).count
      company.disable_ingestion!
      puts "  #{company.name}: purged #{count} posting(s)"
    end

    orphaned = JobPosting.where(company_id: nil)
                         .where("company_name ~* ?", Company::BIG_TECH_NAME_PATTERN)
                         .where.not(status: %w[purged expired])
    puts "Purging #{orphaned.count} orphaned big-tech posting(s) with no linked Company record..."
    orphaned.find_each(&:purge!)
  end

  desc "Purge already-geocoded postings outside the acceptable commute zone (see Geo::CommuteZone)"
  task backfill_commute_zone: :environment do
    candidates = JobPosting.where.not(latitude: nil).where.not(longitude: nil).where.not(status: %w[purged expired])
    purged_count = 0
    candidates.find_each do |posting|
      next unless Geo::CommuteZone.call(posting) == :blocked

      posting.purge!
      purged_count += 1
    end
    puts "Purged #{purged_count} geocoded posting(s) outside the acceptable commute zone."
  end

  desc "Run all job-filter backfills"
  task backfill_all: %i[backfill_big_tech backfill_commute_zone]
end
