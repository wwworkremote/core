# frozen_string_literal: true

# JobPosting's own state machine: facts about the *listing*, independent of
# whether Mike is pursuing it. none -> ignored/expired/purged/archived, with
# restore back to none. Mike's own pipeline stage (favorited/applied/
# interview) and the employer's outcome (offered/rejected/etc) live
# entirely on UserJobPosting -- see TASK-82. Extracted as its own concern to
# keep JobPosting under Metrics/ClassLength -- this is a cohesive state
# machine definition, not a bag of unrelated methods, so it gets a bounded
# context of its own rather than an arbitrary split.
module JobPosting::StatusWorkflow
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength -- one cohesive state machine
  # definition; splitting it across multiple aasm blocks would obscure
  # the transition graph, not simplify it.
  included do
    include AASM

    aasm column: :status, whiny_persistence: true do
      state :none, initial: true
      state :ignored, :purged, :expired, :archived

      event :expire do
        after { log_lifecycle_step("Auto-expired: no activity in 72+ hours") }
        transitions from: %i[none archived ignored], to: :expired
      end

      event :ignore do
        after { log_lifecycle_step("Auto-ignored: outside configured commute zone") }
        transitions from: %i[none], to: :ignored
      end

      event :purge do
        after do
          log_lifecycle_step("Purged by admin")
          # update_column (not update!) deliberately: this is inside the
          # AASM after-callback and must not re-trigger
          # ensure_aasm_transition's status-change guard or run unrelated
          # validation/callback overhead just to null one column.
          # rubocop:disable-next Rails/SkipsModelValidations
          update_column(:embedding, nil) # Instant removal from neural search
        end
        transitions from: %i[none archived ignored], to: :purged
      end

      event :restore do
        after { log_lifecycle_step("Restored to active") }
        # :ignored is included alongside :purged so a posting wrongly
        # auto-ignored (e.g. by a Geo::CommuteZone misclassification) can
        # be brought back once the underlying cause is fixed -- otherwise
        # ignored has no way back to :none at all.
        transitions from: %i[purged ignored], to: :none
      end

      event :archive do
        # :none is the only legal origin -- LinkMonitorJob is the only
        # caller, archiving postings whose links go dead. It already logs
        # its own richer PipelineStep (which URL check failed and how), so
        # unlike the other events here this one has no automatic after
        # callback -- adding one would double-log every dead-link archive.
        transitions from: %i[none], to: :archived
      end
    end

    # Prevent direct status updates
    before_update :ensure_aasm_transition, if: :status_changed?

    # JobPosting.status alone no longer tells you whether the user has
    # decided on a posting -- favorite/apply/interview/archive live
    # entirely on UserJobPosting. Bulk "leave anything already decided
    # alone" operations (triage's candidate query, Source/Company's
    # mark_not_interested!) all need this same exclusion; one shared scope
    # instead of three separate copies of the same query.
    scope :without_pipeline_activity, lambda { |user|
      where.not(id: user.user_job_postings.where.not(status: [nil, "none"]).select(:job_posting_id))
    }
  end
  # rubocop:enable Metrics/BlockLength

  private

  # Guarded on persisted? -- Syncer's ingestion path calls the non-bang
  # `ignore` (transitions in-memory, doesn't save) on a brand-new
  # find_or_initialize_by record before it's ever been saved once, so
  # pipeline_steps.create! would raise ActiveRecord::RecordNotSaved
  # ("parent is saved") for the every-day case of a low-quality posting
  # getting ignored on first ingestion. Nothing worth auditing yet for a
  # posting that doesn't exist as a row until the save a few lines later.
  def log_lifecycle_step(note)
    return unless persisted?

    pipeline_steps.create!(status: aasm.to_state.to_s, note: note)
  end

  def ensure_aasm_transition
    return if aasm.current_event.present?
    return if no_real_status_change?

    errors.add(:status, "cannot be updated directly. Use state machine events.")
    throw(:abort)
  end

  def no_real_status_change?
    status_was.nil? || (status_was == "none" && status == "none")
  end
end
