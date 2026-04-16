# frozen_string_literal: true

class DataAcquisitionManager
  FETCHERS = {
    'adzuna' => {
      class: Adzuna::Fetcher,
      cooldown: 4.hours,
      name: 'Adzuna'
    },
    'arbeitnow' => {
      class: Arbeitnow::Fetcher,
      cooldown: 2.hours,
      name: 'Arbeitnow'
    },
    'hackernews' => {
      class: HackerNews::FetchLatestJobstories,
      cooldown: 15.minutes,
      name: 'HackerNews'
    },
    'himalayas' => {
      class: Himalayas::Fetcher,
      cooldown: 1.hour,
      name: 'Himalayas'
    },
    'jobicy' => {
      class: Jobicy::Fetcher,
      cooldown: 4.hours,
      name: 'Jobicy'
    },
    'remoteok' => {
      class: Remoteok::Fetcher,
      cooldown: 2.hours,
      name: 'RemoteOK'
    },
    'remotive' => {
      class: Remotive::Fetcher,
      cooldown: 1.hour,
      name: 'Remotive'
    },
    'rubyonremote' => {
      class: RubyOnRemote::Scraper,
      cooldown: 4.hours,
      name: 'RubyOnRemote'
    },
    'wwr' => {
      class: Wwr::Fetcher,
      cooldown: 30.minutes,
      name: 'Wwr'
    },
    'yc' => {
      class: Yc::Scraper,
      cooldown: 4.hours,
      name: 'YC'
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
    last_fetched = guard.last_fetched_at(slug)
    can_fetch = guard.can_fetch?(slug, cooldown: config[:cooldown])
    time_until_reset = guard.time_until_reset(slug, cooldown: config[:cooldown])

    {
      slug:,
      name: config[:name],
      last_fetched_at: last_fetched,
      can_fetch: can_fetch,
      time_until_reset: time_until_reset,
      cooldown: config[:cooldown]
    }
  end

  def self.run(slug, force: false)
    config = FETCHERS[slug]
    return { error: 'Fetcher not found' } unless config

    # Many of our fetchers don't yet accept 'force' or any arguments.
    # We should update them to support it.
    fetcher = config[:class].new

    result = if fetcher.method(:call).arity.abs > 0 || fetcher.method(:call).parameters.any? { |p| p[0] == :key || p[0] == :keyreq }
                fetcher.call(force: force)
              else
                fetcher.call
              end

    case result
    when true
      JobBoards::Syncer.new.call
      { success: true }
    when false
      { success: false, error: "Missing API credentials" }
    when :cooldown
      { success: false, error: "Skipped: Cooldown in progress (Force to bypass)" }
    when :missing_source
      { success: false, error: "Internal Error: Data source record missing in database" }
    else
      { success: false, error: "Unexpected result: #{result.inspect}" }
    end
  end
end
