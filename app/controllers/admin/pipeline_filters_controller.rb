# frozen_string_literal: true

# Read-only overview of the various static filtering/routing rules
# scattered across the ingestion pipeline (role families, blocklists,
# quality gates, guardrail patterns, active sources) -- these live as
# Ruby constants, not database rows, so unlike PipelinePrompt they aren't
# editable here, just surfaced in one place for visibility.
class Admin::PipelineFiltersController < Admin::ApplicationController
  # One cohesive read-only assignment of every static filter constant --
  # splitting it into helper methods would fragment a single overview into
  # unreadable pieces for no real simplification.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def index
    @role_families = RoleFamily::FAMILIES
    @big_tech_blocklist = Company::BIG_TECH_NAMES
    @quality_banned_titles = JobBoards::QualityFilter::BANNED_TITLES
    @quality_banned_keywords = JobBoards::QualityFilter::BANNED_KEYWORDS
    @categorizer_categories = JobBoards::Categorizer::CATEGORIES
    @guardrail_patterns = Guardrails::HeuristicScanner::SUSPICIOUS_PATTERNS
    @commute_hyperlocal_radius = ENV.fetch("HYPERLOCAL_RADIUS_MILES", Geo::CommuteZone::DEFAULT_HYPERLOCAL_RADIUS_MILES)
    @commute_station_radius = ENV.fetch("STATION_RADIUS_MILES", Geo::CommuteZone::DEFAULT_STATION_RADIUS_MILES)
    @commute_terminal_radius = ENV.fetch("TERMINAL_WALK_RADIUS_MILES", Geo::CommuteZone::DEFAULT_TERMINAL_WALK_RADIUS_MILES)
    @adapters = Ingestion::AdapterRegistry.all
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
