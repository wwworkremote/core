# frozen_string_literal: true

module JobPostingsHelper
  # Timestamps change on every version and add nothing worth showing --
  # they're not "what changed," just when.
  HISTORY_IGNORED_ATTRS = %w[updated_at created_at].freeze

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
