# frozen_string_literal: true

# The standing job-search criteria (comp floor, culture-over-comp weighting,
# work-authorization, target-level sizing) that get fed verbatim into LLM
# prompts -- interview prep today, matching later.
#
# The real values carry a specific comp figure, so they live in
# `config/job_search_criteria.yml` (gitignored, like `config/commute_zone.yml`).
# `config/job_search_criteria.yml.example` ships the shape. With no file, prompts
# get a neutral placeholder instead of a hardcoded number.
module StandingCriteria
  CONFIG_PATH = Rails.root.join("config/job_search_criteria.yml")

  DEFAULT_LINES = [
    "The candidate's standing job-search criteria are not configured " \
    "(see config/job_search_criteria.yml.example). Do not invent a comp figure or constraint."
  ].freeze

  def self.lines
    return DEFAULT_LINES unless CONFIG_PATH.exist?

    Array(YAML.safe_load_file(CONFIG_PATH)&.dig("criteria")).map(&:to_s).compact_blank.presence || DEFAULT_LINES
  end

  # Bulleted block for interpolation into a prompt's [STANDING_CRITERIA] section.
  def self.prompt_block
    lines.map { |line| "- #{line}" }.join("\n")
  end
end
