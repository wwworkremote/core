# frozen_string_literal: true

# Reads Indeed's api/v1/appStatusJobs row shape for Applications::RowImporter
# -- the exact JSON that endpoint returns, whether it arrived via a HAR
# capture (bin/import_indeed_applications) or a live authenticated fetch
# from the extension while Mike is on myjobs.indeed.com
# (Api::V0::OutcomesController). One import path, two callers, so a schema
# change only needs fixing once.
class Applications::IndeedRowImporter < Applications::RowImporter
  # Employer signal beats self-report; REJECTED beats REVIEWED so a later
  # "still pending" self-report can't downgrade a rejection Indeed already
  # confirmed elsewhere in the same payload.
  OUTCOME_RANK = { "REJECTED" => 3, "REVIEWED" => 2, "CLOSED" => 1 }.freeze

  private

  def source_name
    "Indeed"
  end

  def signature
    Digest::SHA256.hexdigest("indeed-app-#{@row['jobKey']}")
  end

  def native_id_fragment
    "jk=#{@row['jobKey']}"
  end

  def target_url
    @row["jobUrl"]
  end

  def company
    @row.dig("company", "name")
  end

  def title
    @row["jobTitle"]
  end

  def location
    @row["location"]
  end

  def applied_at_from(row)
    row["applyTime"] && Time.zone.at(row["applyTime"].to_i / 1000)
  end

  def outcome_candidates(row)
    { row.dig("statuses", "candidateStatus", "status") => "employer",
      row.dig("statuses", "selfReportedStatus", "status") => "self_reported",
      row.dig("statuses", "employerJobStatus", "status") => "employer" }.compact
  end

  def outcome_for(row)
    outcome_and_source(row).first
  end

  def outcome_source_for(row)
    outcome_and_source(row).last
  end

  def outcome_and_source(row)
    candidates = outcome_candidates(row)
    best = candidates.keys.max_by { |s| OUTCOME_RANK[s] || 0 }
    return [nil, nil] unless best && OUTCOME_RANK.key?(best)

    [best.downcase, candidates[best]]
  end
end
