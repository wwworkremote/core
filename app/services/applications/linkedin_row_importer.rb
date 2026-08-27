# frozen_string_literal: true

# Reads one row of LinkedIn's job-tracker DOM (parsed by
# bin/import_linkedin_tracker) for Applications::RowImporter.
#
# LinkedIn differs from Greenhouse/Indeed in three real ways, not just row
# shape: (1) a row's *stage* (applied/clicked_apply/saved), set per import
# run rather than per row, decides whether this is an apply or a favorite --
# "clicked_apply" means Mike left for the employer's site, and LinkedIn
# can't see whether he finished, so it must never be recorded as applied;
# (2) LinkedIn gives relative ages only ("Applied 3mo ago"), never an exact
# timestamp, so applied_at here is always an approximation -- the fill-only
# default (never overwrite_applied_at?) keeps it from clobbering a real date
# Greenhouse or Indeed already wrote; (3) its only outcome signal is "listing
# closed," a weaker fact than an employer's explicit rejection, so it must
# never overwrite an outcome another source already recorded.
class Applications::LinkedinRowImporter < Applications::RowImporter
  # LinkedIn's own vocabulary -> our event.
  STAGES = { "applied" => "apply", "clicked_apply" => "favorite", "saved" => "favorite" }.freeze
  AGE_UNITS = { "d" => :days, "w" => :weeks, "mo" => :months, "yr" => :years }.freeze

  def self.call(row, user:, stage:)
    new(row, user, stage).call
  end

  def initialize(row, user, stage)
    super(row, user)
    @stage = stage
  end

  private

  def source_name
    "LinkedIn"
  end

  def signature
    Digest::SHA256.hexdigest("linkedin-tracker-#{@row[:id]}")
  end

  def native_id_fragment
    "/jobs/view/#{@row[:id]}"
  end

  def target_url
    "https://www.linkedin.com/jobs/view/#{@row[:id]}/"
  end

  def company
    @row[:company]
  end

  def title
    @row[:title]
  end

  def location
    @row[:location]
  end

  def status_event
    STAGES.fetch(@stage)
  end

  # Relative ages are all LinkedIn gives ("Applied 3mo ago"). Approximate is
  # enough for a staleness signal (TASK-81) and is never treated as more
  # certain than it is -- see #overwrite_applied_at? (inherited: false).
  def applied_at_from(row)
    count, unit = row[:note].to_s.match(/(\d+)\s*(d|w|mo|yr)\b/)&.captures
    return nil unless count

    count.to_i.public_send(AGE_UNITS.fetch(unit)).ago
  end

  def outcome_for(row)
    "closed" if row[:closed]
  end

  def outcome_source_for(_row)
    "self_reported"
  end

  # LinkedIn's only outcome signal is "listing closed" -- a real employer
  # rejection (Indeed) or reject-stage signal (Greenhouse) is a stronger
  # fact and must not be clobbered by it.
  def outcome_overwrite?
    false
  end

  # Idempotency: match on the age string ("Applied 3mo ago") rather than the
  # whole note, since the trailing "imported <date>" changes every run and a
  # full-string compare would never see the duplicate.
  def after_advance(tracked)
    note = note_for
    return if note.blank? || already_noted?(tracked, note)

    tracked.update!(notes: [tracked.notes, note].compact_blank.join("\n"))
  end

  def already_noted?(tracked, note)
    tracked.notes.to_s.include?(note[/^[^(]+/].to_s.strip)
  end

  def note_for
    return if @row[:note].blank?

    date = applied_at_from(@row)&.to_date
    "LinkedIn tracker: #{@row[:note]} (~#{date}), imported #{Date.current}"
  end
end
