# frozen_string_literal: true

# Reads my.greenhouse.io's applications.json row shape for
# Applications::RowImporter -- shared by bin/import_greenhouse_applications'
# HAR replay and Api::V0::OutcomesController#greenhouse's live extension
# capture, same split as Applications::IndeedRowImporter.
#
# Outcome signal here is thinner than Indeed's: currentStage came back null
# across every application checked 2026-08-24 (employers not sharing stage
# with the candidate portal), so the only real signal is an application
# showing up in the "inactive" bucket at all -- Greenhouse flips an
# application inactive on rejection, withdrawal, or the req closing, and the
# portal doesn't say which. Recorded as "closed", not "rejected": that
# distinction is real and this app can't see it, so don't claim more
# certainty than the source has.
class Applications::GreenhouseRowImporter < Applications::RowImporter
  private

  def source_name
    "Greenhouse"
  end

  def signature
    Digest::SHA256.hexdigest("greenhouse-app-#{@row['id']}")
  end

  def native_id_fragment
    "/jobs/#{@row['job_post_id']}"
  end

  def target_url
    @row["job_post_url"]
  end

  def company
    @row["company_name"]
  end

  def title
    @row["job_title"]
  end

  def location
    @row["locations"]
  end

  def applied_at_from(row)
    return nil if row["applied_at"].blank?

    Time.zone.parse(row["applied_at"])
  rescue ArgumentError, TypeError
    nil
  end

  def outcome_for(row)
    stage = row["currentStage"].to_s
    return "rejected" if stage.match?(/reject/i)
    return "closed" if row["inactive"] == true

    nil
  end

  # Applied_at is always authoritative here, unlike Indeed's fill-only
  # semantic: this may overwrite a worse LinkedIn relative-age
  # approximation that got there first.
  def overwrite_applied_at?
    true
  end
end
