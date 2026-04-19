# frozen_string_literal: true

class DataAcquisitionManager
  FETCHERS = {
    'adzuna' => {
      class: Adzuna::Fetcher,
      cooldown: 4.hours,
      name: 'Adzuna',
      type: 'API'
    },
    'arbeitnow' => {
      class: Arbeitnow::Fetcher,
      cooldown: 2.hours,
      name: 'Arbeitnow',
      type: 'Feed'
    },
    'greenhouse' => {
      class: Greenhouse::Fetcher,
      cooldown: 4.hours,
      name: 'Greenhouse',
      type: 'Scraper'
    },
    'hackernews' => {
      class: HackerNews::FetchLatestJobstories,
      cooldown: 15.minutes,
      name: 'HackerNews',
      type: 'API'
    },
    'jobicy' => {
      class: Jobicy::Fetcher,
      cooldown: 4.hours,
      name: 'Jobicy',
      type: 'Feed'
    },
    'lever' => {
      class: Lever::Fetcher,
      cooldown: 4.hours,
      name: 'Lever',
      type: 'Scraper'
    },
    'remotive' => {
      class: Remotive::Fetcher,
      cooldown: 1.hour,
      name: 'Remotive',
      type: 'API'
    },
    'wwr' => {
      class: Wwr::Fetcher,
      cooldown: 30.minutes,
      name: 'Wwr',
      type: 'Scraper'
    },
    'yc' => {
      class: Yc::Scraper,
      cooldown: 4.hours,
      name: 'YC',
      type: 'Scraper'
    },
    'cord' => {
      class: Scraper::CrawlDiscoveryJob,
      cooldown: 2.hours,
      name: 'Cord',
      type: 'Scraper'
    },
    'email_indeed' => {
      class: EmailIngestion::Importer,
      cooldown: 1.hour,
      name: 'Email (Indeed)',
      type: 'Email'
    },
    'email_adzuna' => {
      class: EmailIngestion::Importer,
      cooldown: 1.hour,
      name: 'Email (Adzuna)',
      type: 'Email'
    },
    'email_linkedin' => {
      class: EmailIngestion::Importer,
      cooldown: 1.hour,
      name: 'Email (LinkedIn)',
      type: 'Email'
    }
  }.freeze

  include ApiGuard

  def self.fetchers
    FETCHERS.map do |slug, config|
      {
        slug:,
        name: config[:name],
        cooldown: config[:cooldown]
      }
    end
  end

  def self.status(slug)
    config = FETCHERS[slug]
    return nil unless config

    # Ensure source exists
    source = JobBoards::Source.find_or_create_by!(slug:) do |s|
      s.name = config[:name]
    end
    JobBoards::Query.find_or_create_by!(source_id: source.id)

    guard = Object.new.extend(ApiGuard)
    # Fallback to model data if ApiGuard returns nil
    last_fetched = guard.last_fetched_at(slug) || source.last_synced_at
    can_fetch = guard.can_fetch?(slug, cooldown: config[:cooldown])
    time_until_reset = guard.time_until_reset(slug, cooldown: config[:cooldown])

    {
      slug:,
      name: config[:name],
      last_fetched_at: last_fetched,
      last_ingested_at: source.last_ingested_at,
      can_fetch: can_fetch,
      time_until_reset: time_until_reset,
      cooldown: config[:cooldown]
    }
  end

  def self.run_all(force: false)
    results = {}
    FETCHERS.each_key do |slug|
      results[slug] = run(slug, force:)
    end
    results
  end

  def self.run(slug, force: false)
    config = FETCHERS[slug]
    return { error: 'Fetcher not found' } unless config

    # Ensure source exists and track the start of sync
    source = JobBoards::Source.find_or_create_by!(slug:) do |s|
      s.name = config[:name]
    end
    source.update!(last_synced_at: Time.current)

    fetcher = config[:class].new
    method = fetcher.method(:call)

    # Detect if fetcher accepts 'force' or 'source' as keyword arguments
    keyword_params = %i[key keyreq]
    result = if method.parameters.any? { |p| keyword_params.include?(p[0]) }
               args = { force: }
               args[:source] = slug.split('_').last if slug.start_with?('email_')
               fetcher.call(**args)
             else
               fetcher.call
             end

    case result
    when true
      # Update ingestion time if postings were actually synced
      syncer_result = JobBoards::Syncer.new.call
      source.update!(last_ingested_at: Time.current) if syncer_result
      { success: true }
    when false
      { success: false, error: 'Fetcher reported failure (Check logs)' }
    when :cooldown
      { success: false, error: 'Skipped: Cooldown in progress (Force to bypass)' }
    when :missing_source
      { success: false, error: 'Internal Error: Data source record missing in database' }
    else
      { success: false, error: "Unexpected result: #{result.inspect}" }
    end
  end
end
