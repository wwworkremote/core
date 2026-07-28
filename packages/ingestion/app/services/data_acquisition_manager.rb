# frozen_string_literal: true

class DataAcquisitionManager
  include ApiGuard

  def self.fetchers
    Ingestion::AdapterRegistry.all.map { |slug, config| fetcher_summary(slug, config) }
  end

  def self.fetcher_summary(slug, config)
    { slug: slug, name: config[:name], cooldown: config[:cooldown] }
  end

  def self.status(slug)
    config = Ingestion::AdapterRegistry.get(slug)
    return nil unless config

    build_status(slug, config)
  end

  def self.build_status(slug, config)
    guard = Object.new.extend(ApiGuard)
    source = JobBoards::Source.find_by(slug: slug)
    base = { slug: slug, name: config[:name], cooldown: config[:cooldown] }
    base.merge(guard_status_fields(slug, config, guard, source))
  end

  def self.guard_status_fields(slug, config, guard, source)
    fetch_fields = { last_fetched_at: guard.last_fetched_at(slug) || source&.last_synced_at,
                     last_ingested_at: source&.last_ingested_at }
    fetch_fields.merge(guard_availability_fields(slug, config, guard))
  end

  def self.guard_availability_fields(slug, config, guard)
    {
      can_fetch: !guard.can_fetch?(slug, cooldown: config[:cooldown]).nil?,
      time_until_reset: reset_countdown(guard, slug, config)
    }
  end

  def self.reset_countdown(guard, slug, config)
    guard.time_until_reset(slug, cooldown: config[:cooldown]) || 0
  rescue StandardError
    0
  end

  def self.run_all(force: false)
    Ingestion::AdapterRegistry.all.each_key.index_with { |slug| run(slug, force:) }
  end

  def self.run(slug, force: false)
    config = Ingestion::AdapterRegistry.get(slug)
    return { error: "Fetcher not found" } unless config
    return { success: false, error: "Pipelines are globally paused." } if SystemSetting.paused? && !force

    source_for(slug, config).update!(last_synced_at: Time.current)
    dispatch(slug, config, force)
  end

  # Race-condition-safe find-or-create: a concurrent run can lose the create
  # race, so retry the find once RecordNotUnique proves the row now exists.
  def self.source_for(slug, config)
    JobBoards::Source.find_or_create_by!(slug: slug) { |s| s.name = config[:name] }
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.dispatch(slug, config, force)
    return CrawlRunner.call(slug, config) if config[:class] == Scraper::CrawlDiscoveryJob
    return run_job(slug, config, force) if config[:class].respond_to?(:perform_later)

    ServiceRunner.call(slug, config, force)
  end

  def self.run_job(slug, config, _force)
    args = config[:class] == EmailImportJob ? [slug.split("_").last] : []
    config[:class].perform_later(*args)
    { success: true }
  end
end
