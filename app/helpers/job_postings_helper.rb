# frozen_string_literal: true

module JobPostingsHelper
  # Timestamps change on every version and add nothing worth showing --
  # they're not "what changed," just when.
  HISTORY_IGNORED_ATTRS = %w[updated_at created_at].freeze

  # Plain-language conclusions about one posting, worst first.
  #
  # The raw fields (country_code, crawl_status, enriched_at, two status
  # columns) are all on screen, but reading them requires knowing what each
  # one implies -- which is work this tool should do rather than delegate.
  # Each entry is [severity, sentence]; the sentence states the finding and
  # what it means, so no derivation is needed to act on it.
  #
  # ponytail: a flat list of independent checks. No rules engine until there
  # are enough of these to need one.
  def posting_findings(posting, tracked)
    checks = [geo_finding(posting), status_drift_finding(posting, tracked),
              enrichment_finding(posting), expiry_finding(posting)]
    checks.compact
  end

  NON_US = "This is a %s posting. It's outside your US-only rule and shouldn't be in your feed."
  NO_COUNTRY = "No country recorded, so the US-only rule can't be applied to it."

  private

  def geo_finding(posting)
    case posting.country_code.presence
    when "US" then nil
    when nil then [:warn, NO_COUNTRY]
    else [:bad, format(NON_US, posting.country_code)]
    end
  end

  # The two AASM machines drift silently (TASK-82); a mismatch usually means a
  # transition was written to one and not the other.
  def status_drift_finding(posting, tracked)
    return nil if tracked.nil? || tracked.status == posting.status

    [:warn, "You have this as \"#{tracked.status}\" but the posting says \"#{posting.status}\" — these disagree."]
  end

  def enrichment_finding(posting)
    return nil if posting.enriched_at.present?

    [:info, "Never enriched, so the description and salary may be incomplete."]
  end

  def expiry_finding(posting)
    return nil unless posting.status == "expired"

    [:info, "This posting is expired — the listing is probably gone."]
  end

  public

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
