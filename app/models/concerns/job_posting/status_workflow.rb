# frozen_string_literal: true

# The JobPosting application-pipeline state machine: none -> favorited ->
# applied -> interview -> offered, with archive/ignore/expire/purge side
# paths. Extracted as its own concern to keep JobPosting under
# Metrics/ClassLength -- this is a cohesive state machine definition, not
# a bag of unrelated methods, so it gets a bounded context of its own
# rather than an arbitrary split.
module JobPosting::StatusWorkflow
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength -- one cohesive state machine
  # definition; splitting it across multiple aasm blocks would obscure
  # the transition graph, not simplify it.
  included do
    include AASM

    aasm column: :status, whiny_persistence: true do
      state :none, initial: true
      state :favorited, :applied, :interview, :offered, :archived, :ignored, :purged, :expired

      event :favorite do
        transitions from: %i[none archived ignored purged expired], to: :favorited
      end

      event :expire do
        transitions from: %i[none favorited archived ignored], to: :expired
      end

      event :ignore do
        transitions from: %i[none], to: :ignored
      end

      event :purge do
        after do
          # update_column (not update!) deliberately: this is inside the
          # AASM after-callback and must not re-trigger
          # ensure_aasm_transition's status-change guard or run unrelated
          # validation/callback overhead just to null one column.
          # rubocop:disable Rails/SkipsModelValidations
          update_column(:embedding, nil) # Instant removal from neural search
          # rubocop:enable Rails/SkipsModelValidations
        end
        transitions from: %i[none favorited archived ignored], to: :purged
      end

      event :restore do
        # :ignored is included alongside :purged so a posting wrongly
        # auto-ignored (e.g. by a Geo::CommuteZone misclassification) can
        # be brought back once the underlying cause is fixed -- otherwise
        # ignored has no way back to :none at all.
        transitions from: %i[purged ignored], to: :none
      end

      event :apply do
        transitions from: %i[favorited interview], to: :applied
      end

      event :interview do
        transitions from: %i[favorited applied], to: :interview
      end

      event :offer do
        transitions from: %i[favorited applied interview], to: :offered
      end

      event :archive do
        # :none is included so LinkMonitorJob can archive postings whose
        # links go dead before any user ever acts on them.
        transitions from: %i[none favorited applied interview offered], to: :archived
      end
    end

    # Prevent direct status updates
    before_update :ensure_aasm_transition, if: :status_changed?
  end
  # rubocop:enable Metrics/BlockLength

  private

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
