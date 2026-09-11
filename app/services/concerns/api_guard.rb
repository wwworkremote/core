# frozen_string_literal: true

# Shared logic for rate limiting and circuit breaking across job board clients.
# Uses SolidCache directly (not Rails.cache) for distributed lock persistence --
# Rails.cache is a NullStore in development unless `rails dev:cache` has been
# run, which silently no-ops the circuit breaker for lock/cooldown state that
# must actually persist. That toggle is meant for view/fragment caching, not
# functional state, so this bypasses it in every environment.
module ApiGuard
  extend ActiveSupport::Concern

  def self.store
    ActiveSupport::Cache.lookup_store(:solid_cache_store)
  end

  # Executes a block within the protection of the API guard.
  # @param source_slug [String] Unique identifier for the job board.
  # @param cooldown [ActiveSupport::Duration] Interval between fetches.
  # @param force [Boolean] Bypasses the cooldown (but not the circuit breaker lock).
  # @return [Symbol, Object] :locked, :cooldown, or the block's return value.
  def with_api_guard(source_slug, cooldown: 15.minutes, force: false)
    return :locked if source_locked?(source_slug)

    source = JobBoards::Source.find_by(slug: source_slug) || (return missing_source(source_slug))
    return :cooldown if within_cooldown?(source_slug, cooldown, force)

    yield(source)
    record_fetch(source_slug)
  end

  # Mutator, not a query -- returns true to match with_api_guard's documented
  # success value, not to signal a yes/no question.
  # rubocop:disable-next Naming/PredicateMethod
  def record_fetch(source_slug)
    ApiGuard.store.write("api_guard:#{source_slug}:last_fetched_at", Time.zone.now)
    true
  end

  def lock_source!(source_slug, duration: 1.hour)
    Rails.logger.warn "[ApiGuard] ⚡ Circuit Breaker Tripped for #{source_slug}. Locking for #{duration.inspect}."
    ApiGuard.store.write("api_guard:#{source_slug}:locked_until", duration.from_now)
  end

  def unlock_source!(source_slug)
    Rails.logger.info "[ApiGuard] 🔓 Unlocking #{source_slug}."
    ApiGuard.store.delete("api_guard:#{source_slug}:locked_until")
  end

  def source_locked?(source_slug)
    locked_until = ApiGuard.store.read("api_guard:#{source_slug}:locked_until")
    return false unless locked_until
    return true if locked_until > Time.zone.now

    # Lock expired, clean up
    ApiGuard.store.delete("api_guard:#{source_slug}:locked_until")
    false
  end

  def last_fetched_at(source_slug)
    ApiGuard.store.read("api_guard:#{source_slug}:last_fetched_at")
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

  def missing_source(source_slug)
    Rails.logger.warn "[ApiGuard] Source #{source_slug} not found in database. Skipping."
    :missing_source
  end

  def within_cooldown?(source_slug, cooldown, force)
    last_fetched = last_fetched_at(source_slug)
    return false if force || !last_fetched || last_fetched <= cooldown.ago

    Rails.logger.info "[ApiGuard] Skipping #{source_slug}, last fetched #{time_ago_in_words(last_fetched)} ago."
    true
  end

  def time_ago_in_words(time)
    ActionController::Base.helpers.time_ago_in_words(time)
  end
end
