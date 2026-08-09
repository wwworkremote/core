# frozen_string_literal: true

# Rebuilds the job_posting_trends rollup from scratch on every run --
# simpler and correctness-safe at this data volume than maintaining an
# incremental delta (which would need special handling for retroactive
# title edits and backfilled postings).
module JobPostingTrendRollup
  UNCATEGORIZED = "uncategorized"

  def self.call
    upsert_counts(weekly_family_counts)
  end

  def self.weekly_family_counts
    counts = Hash.new(0)
    JobPosting.where.not(created_at: nil).pluck(:title, :created_at).each do |title, created_at|
      counts[bucket_key(title, created_at)] += 1
    end
    counts
  end

  def self.bucket_key(title, created_at)
    [created_at.to_date.beginning_of_week, RoleFamily.for(title) || UNCATEGORIZED]
  end

  def self.upsert_counts(counts)
    return if counts.empty?

    now = Time.current
    rows = counts.map { |(week_start, family), count| trend_row(week_start, family, count, now) }
    # Bulk upsert of derived aggregate counts, not user data -- no model
    # validations apply here.
    # rubocop:disable Rails/SkipsModelValidations
    JobPostingTrend.upsert_all(rows, unique_by: :index_job_posting_trends_on_week_and_family)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def self.trend_row(week_start, family, count, timestamp)
    { week_start: week_start, role_family: family.to_s, postings_count: count,
      created_at: timestamp, updated_at: timestamp }
  end
end
