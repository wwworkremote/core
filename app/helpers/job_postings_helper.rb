# frozen_string_literal: true

module JobPostingsHelper
  # Timestamps change on every version and add nothing worth showing --
  # they're not "what changed," just when.
  HISTORY_IGNORED_ATTRS = %w[updated_at created_at].freeze

  ANSWER_SOURCE_BADGE_CLASSES = {
    "canned" => "border-success/40 text-success",
    "submitted" => "border-info/40 text-info",
    "ai" => "border-accent/40 text-accent"
  }.freeze

  # Provenance is the entire point of this badge, so `submitted` -- the answer
  # the user actually sent to the employer -- must not render as "AI
  # Generated". Unknown/legacy sources fall back to `ai`, which is what the
  # two-way ternary this replaced already did.
  def answer_source_badge(source)
    key = ANSWER_SOURCE_BADGE_CLASSES.key?(source) ? source : "ai"
    [ANSWER_SOURCE_BADGE_CLASSES.fetch(key), t("job_postings.show.qa.badges.#{key}")]
  end

  def safe_job_url(url)
    return "#" if url.blank?

    valid_job_url?(url) ? url : "#"
  end

  # Versions recorded before object_changes tracking was added have no
  # changeset to show -- returns nil rather than an empty array so the view
  # can distinguish "nothing changed" from "no data captured."
  def version_changes_summary(version)
    changes = version.changeset&.except(*HISTORY_IGNORED_ATTRS)
    return nil if changes.blank?

    changes.map { |attr, (old_value, new_value)|
      "#{attr.humanize}: #{format_history_value(old_value)} → #{format_history_value(new_value)}"
    }
  end

  private

  def format_history_value(value)
    case value
    when nil then "—"
    when String, Numeric, TrueClass, FalseClass then value.to_s.truncate(60)
    else "changed"
    end
  end

  def valid_job_url?(url)
    %w[http https].include?(URI.parse(url).scheme)
  rescue URI::InvalidURIError
    false
  end
end
