# frozen_string_literal: true

module ApiGuard
  extend ActiveSupport::Concern

  def with_api_guard(source_slug, cooldown: 15.minutes)
    source = JobBoards::Source.find_by!(slug: source_slug)
    
    # Check if we are in the cooldown period
    last_fetched = Kredis.datetime("api_guard:#{source_slug}:last_fetched_at")
    if last_fetched.value && last_fetched.value > cooldown.ago
      Rails.logger.info "[ApiGuard] Skipping #{source_slug}, last fetched #{time_ago_in_words(last_fetched.value)} ago."
      return false
    end

    yield(source)

    # If successful, update the timestamp
    last_fetched.value = Time.zone.now
    true
  end

  private

  def time_ago_in_words(time)
    ActionController::Base.helpers.time_ago_in_words(time)
  end
end
