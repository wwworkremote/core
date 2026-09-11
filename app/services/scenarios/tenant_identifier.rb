# frozen_string_literal: true

# Derives the per-employer identifier for a TenantIdentity from a guided
# session's source URL (ADR 010 §4). Value-free: the employer's own board
# slug / tenant subdomain, which is already in the URL -- never a credential.
# Returns nil when the URL carries no attributable employer.
class Scenarios::TenantIdentifier
  # host substring => how to pull the slug from the URL.
  SLUG_FROM_PATH = %w[greenhouse.io lever.co ashbyhq.com breezy.hr].freeze

  def self.call(provider, source_url)
    new(provider, source_url).call
  end

  def initialize(provider, source_url)
    @provider = provider.to_s
    @uri = URI.parse(source_url.to_s)
  rescue URI::InvalidURIError
    @uri = nil
  end

  def call
    return nil unless host
    return workday_subdomain if host.end_with?("myworkdayjobs.com")
    return path_slug if path_slug_provider?

    host.delete_prefix("www.")
  end

  private

  def host
    @host ||= @uri&.host&.downcase
  end

  def path_slug_provider?
    SLUG_FROM_PATH.any? { |h| host.end_with?(h) }
  end

  def workday_subdomain
    host.split(".").first.presence
  end

  # boards.greenhouse.io/acme/jobs/123 -> acme
  def path_slug
    @uri.path.split("/").compact_blank.first
  end
end
