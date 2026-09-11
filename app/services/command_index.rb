# frozen_string_literal: true

# Builds the Cmd+K command palette's searchable route index by introspecting
# Rails.application.routes directly -- the route set already is the sitemap,
# nothing to hand-maintain separately (TASK-76).
class CommandIndex
  EXCLUDED_PATH_PREFIXES = %w[/rails/ /charts/ /api/ /recede /refresh /resume_historical].freeze
  EXCLUDED_NAMES = %w[home_index].freeze

  # Only the labels that read badly from a bare `.titleize` -- everything
  # else falls back to it rather than hand-maintaining 40+ entries.
  LABEL_OVERRIDES = {
    "root" => "Dashboard",
    "admin_root" => "Admin Dashboard",
    "user_job_postings" => "Saved Jobs",
    "llm_chats" => "AI Chats",
    "new_llm_chat" => "New AI Chat",
    "models" => "AI Models",
    "admin_observability" => "System Health",
    "admin_jobs" => "Background Jobs",
    "job_posting_triage" => "Triage",
    "data_fetchers" => "Data Sources"
  }.freeze

  def self.entries
    Rails.cache.fetch("command_index/entries") { build_entries }
  end

  def self.build_entries
    Rails.application.routes.routes.filter_map { |route| entry_for(route) }
                                   .sort_by { |entry| entry[:label] }
  end
  private_class_method :build_entries

  def self.entry_for(route)
    return nil unless navigable?(route)

    { label: LABEL_OVERRIDES[route.name] || route.name.titleize, path: path_for(route) }
  end
  private_class_method :entry_for

  def self.navigable?(route)
    return false if route.name.blank? || route.verb != "GET"
    return false if EXCLUDED_NAMES.include?(route.name)

    navigable_path?(path_for(route))
  end
  private_class_method :navigable?

  def self.navigable_path?(path)
    return false if path.match?(/:\w+/)
    return false if EXCLUDED_PATH_PREFIXES.any? { |prefix| path.start_with?(prefix) }

    path.exclude?("(/:database)")
  end
  private_class_method :navigable_path?

  def self.path_for(route)
    route.path.spec.to_s.sub("(.:format)", "")
  end
  private_class_method :path_for
end
