# frozen_string_literal: true

class DataAcquisitionManager
  include ApiGuard

  def self.fetchers
    Ingestion::AdapterRegistry.all.map do |slug, config|
      {
        slug: slug,
        name: config[:name],
        cooldown: config[:cooldown]
      }
    end
  end

  def self.status(slug)
    config = Ingestion::AdapterRegistry.get(slug)
    return nil unless config

    # Use find_by instead of find_or_create to avoid writes in views/GET requests
    source = JobBoards::Source.find_by(slug: slug)

    guard = Object.new.extend(ApiGuard)
    last_fetched = guard.last_fetched_at(slug) || source&.last_synced_at
    can_fetch = guard.can_fetch?(slug, cooldown: config[:cooldown])
    time_until_reset = guard.time_until_reset(slug, cooldown: config[:cooldown]) rescue 0

    {
      slug: slug,
      name: config[:name],
      last_fetched_at: last_fetched,
      last_ingested_at: source&.last_ingested_at,
      can_fetch: !can_fetch.nil?,
      time_until_reset: time_until_reset || 0,
      cooldown: config[:cooldown]
    }
  end

  def self.run_all(force: false)
    results = {}
    Ingestion::AdapterRegistry.all.each_key do |slug|
      results[slug] = run(slug, force:)
    end
    results
  end

  def self.run(slug, force: false)
    config = Ingestion::AdapterRegistry.get(slug)
    return { error: "Fetcher not found" } unless config

    return { success: false, error: "Pipelines are globally paused." } if SystemSetting.paused? && !force

    # Ensure source exists with race condition handling
    begin
      source = JobBoards::Source.find_or_create_by!(slug: slug) do |s|
        s.name = config[:name]
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    source.update!(last_synced_at: Time.current)

    if config[:class] == Scraper::CrawlDiscoveryJob
      run_crawler(slug, config, force)
    elsif config[:class].respond_to?(:perform_later)
      run_job(slug, config, force)
    else
      run_service(slug, config, force)
    end
  end

  def self.run_crawler(slug, config, _force)
    queries = BoardQuery.where(board_name: slug.downcase)

    if queries.any?
      queries.each do |q|
        url = q.build_url || q.query_params["start_url"]
        selector = q.query_params["selector"] || 'a[href*="/job/"]'
        config[:class].perform_later(slug, url, selector) if url.present?
      end
      { success: true }
    else
      default_url = case slug
                    when "cord" then "https://cord.com/search/jobs/software-developer"
                    when "linkedin" then "https://www.linkedin.com/jobs/search/?keywords=Software%20Engineer"
                    when "indeed" then "https://www.indeed.com/jobs?q=Software%20Engineer"
                    when "dice" then "https://www.dice.com/jobs?q=Staff%20Engineer&location=Remote"
                    when "remoteok" then "https://remoteok.com/remote-ruby-jobs"
                    when "wwr" then "https://weworkremotely.com/categories/remote-programming-jobs"
                    end

      if default_url
        config[:class].perform_later(slug, default_url, 'a[href*="/job/"]')
        { success: true }
      else
        { success: false, error: "No active queries found for #{slug}" }
      end
    end
  end

  def self.run_job(slug, config, _force)
    if config[:class] == EmailImportJob
      config[:class].perform_later(slug.split("_").last)
    else
      config[:class].perform_later
    end
    { success: true }
  end

  def self.run_service(slug, config, force)
    fetcher = config[:class].new
    method_sig = config[:class].instance_method(:call)

    call_args = {}
    call_args[:force] = force if method_sig.parameters.any? { |p| p[1] == :force }
    call_args[:source] = slug.split("_").last if slug.start_with?("email_") && method_sig.parameters.any? { |p|
      p[1] == :source
    }

    result_raw = call_args.any? ? fetcher.call(**call_args) : fetcher.call

    result = case result_raw
             when true then { success: true }
             when false then { success: false, error: "Fetcher reported failure" }
             when Hash then result_raw
             else { success: true }
             end

    if result[:success]
      syncer_result = JobBoards::Syncer.new.call
      JobBoards::Source.find_by(slug: slug)&.update!(last_ingested_at: Time.current) if syncer_result
    end

    result
  end
end
