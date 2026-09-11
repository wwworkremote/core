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
    checks = [outcome_finding(tracked), geo_finding(posting),
              enrichment_finding(posting), expiry_finding(posting)]
    checks.compact
  end

  NON_US = "This is a %s posting. It's outside your US-only rule and shouldn't be in your feed."
  NO_COUNTRY = "No country recorded, so the US-only rule can't be applied to it."
  OUTCOME_FINDINGS = {
    "rejected" => [:bad, "The employer rejected this application."],
    "reviewed" => [:info, "Employer has reviewed this — no decision yet."],
    "closed" => [:info, "The posting closed after you applied."]
  }.freeze

  private

  def outcome_finding(tracked)
    OUTCOME_FINDINGS[tracked&.outcome]
  end

  def geo_finding(posting)
    case posting.country_code.presence
    when "US" then nil
    when nil then [:warn, NO_COUNTRY]
    else [:bad, format(NON_US, posting.country_code)]
    end
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

  PIPELINE_STATUS_BADGE_CLASSES = {
    lifecycle_archived: "border-white/20 text-slate-400",
    lifecycle_ignored: "border-error/40 text-error",
    lifecycle_expired: "border-warning/40 text-warning",
    lifecycle_purged: "border-error/60 text-error",
    outcome_offered: "border-success/40 text-success",
    outcome_rejected: "border-rose-500/40 text-rose-400",
    outcome_reviewed: "border-amber-500/40 text-amber-400",
    outcome_closed: "border-slate-500/40 text-slate-400",
    pipeline_favorited: "border-primary/40 text-primary",
    pipeline_applied: "border-info/40 text-info",
    pipeline_interview: "border-accent/40 text-accent",
    pipeline_archived: "border-white/20 text-slate-400"
  }.freeze

  # Badge-outline styling for Pipeline::DisplayStatus's result -- [css,
  # label] or nil, matching answer_source_badge's shape above.
  def pipeline_status_badge(job_posting, user_job)
    badge = Pipeline::DisplayStatus.call(job_posting: job_posting, user_job: user_job)
    return nil unless badge

    [PIPELINE_STATUS_BADGE_CLASSES.fetch(badge[:semantic]), badge[:label]]
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
