# frozen_string_literal: true

module ApiGuard
  extend ActiveSupport::Concern

  def with_api_guard(source_slug, cooldown: 15.minutes, force: false)
    return :locked if source_locked?(source_slug)

    source = JobBoards::Source.find_by(slug: source_slug)
    unless source
      Rails.logger.warn "[ApiGuard] Source #{source_slug} not found in database. Skipping."
      return :missing_source
    end

    last_fetched_at = last_fetched_at(source_slug)
    if !force && last_fetched_at && last_fetched_at > cooldown.ago
      Rails.logger.info "[ApiGuard] Skipping #{source_slug}, last fetched #{time_ago_in_words(last_fetched_at)} ago."
      return :cooldown
    end

    yield(source)

    # If successful, update the timestamp in the database-backed cache
    Rails.cache.write("api_guard:#{source_slug}:last_fetched_at", Time.zone.now)
    true
  end

  def lock_source!(source_slug, duration: 1.hour)
    Rails.logger.warn "[ApiGuard] ⚡ Circuit Breaker Tripped for #{source_slug}. Locking for #{duration.inspect}."
    Rails.cache.write("api_guard:#{source_slug}:locked_until", duration.from_now)
  end

  def source_locked?(source_slug)
    locked_until = Rails.cache.read("api_guard:#{source_slug}:locked_until")
    return false unless locked_until

    if locked_until > Time.zone.now
      true
    else
      # Lock expired, clean up
      Rails.cache.delete("api_guard:#{source_slug}:locked_until")
      false
    end
  end

  def last_fetched_at(source_slug)
    Rails.cache.read("api_guard:#{source_slug}:last_fetched_at")
  end

  def can_fetch?(source_slug, cooldown: 15.minutes)
    last_fetched = last_fetched_at(source_slug)
    !last_fetched || last_fetched <= cooldown.ago
  end

  def time_until_reset(source_slug, cooldown: 15.minutes)
    last_fetched = last_fetched_at(source_slug)
    return 0 if !last_fetched || last_fetched <= cooldown.ago

    (last_fetched + cooldown) - Time.zone.now
  end

  private

  def time_ago_in_words(time)
    ActionController::Base.helpers.time_ago_in_words(time)
  end
end
