# frozen_string_literal: true

# Two invariants a resync must never violate -- split out of JobBoards::
# Syncer to keep the sync-flow class itself under Metrics/ClassLength.
# Returns true/false if a shield applied (the caller should return that
# as-is), or nil if neither applied and normal mapping should proceed.
class JobBoards::Syncer::EditShield
  def self.call(job_posting, doc)
    new(job_posting, doc).call
  end

  def initialize(job_posting, doc)
    @job_posting = job_posting
    @doc = doc
  end

  def call
    return apply_reseen! if @job_posting.persisted? && @job_posting.status != "purged"
    return apply_purged! if @job_posting.status == "purged"

    nil
  end

  private

  # These mutate (increment!/touch/update!) and their `true` return is
  # incidental -- used by the caller for early-return control flow, not a
  # query result -- so naming them with `!` (mutation) rather than `?`
  # (side-effect-free query) is the more accurate signal, despite
  # Naming/PredicateMethod wanting `?` for anything boolean-returning.
  # rubocop:disable Naming/PredicateMethod

  # An existing, non-purged posting is never overwritten by a resync
  # (preserves user edits/manual enrichments) -- just bump the seen count.
  # increment!/touch deliberately skip validations here: this is a
  # lightweight counter/timestamp bump on an already-valid, already-saved
  # record, not a change worth re-validating.
  # rubocop:disable-next Rails/SkipsModelValidations
  def apply_reseen!
    @job_posting.increment!(:seen_count)
    @job_posting.touch(:updated_at)
    mark_processed
    true
  end

  # A user-purged posting is never reactivated by a resync.
  def apply_purged!
    mark_processed
    true
  end
  # rubocop:enable Naming/PredicateMethod

  def mark_processed
    @doc.update!(aasm_state: "processed")
  end
end
