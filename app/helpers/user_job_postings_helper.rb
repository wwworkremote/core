# frozen_string_literal: true

module UserJobPostingsHelper
  OUTCOME_BADGE_CLASSES = {
    outcome_rejected: "bg-rose-900/20 text-rose-500 border-rose-500/10",
    outcome_reviewed: "bg-amber-900/20 text-amber-500 border-amber-500/10",
    outcome_closed: "bg-slate-700/40 text-slate-400 border-slate-500/10"
  }.freeze

  # Pill styling for Pipeline::DisplayStatus.outcome's result -- [css,
  # label] or nil. Deliberately narrower than JobPostingsHelper's
  # pipeline_status_badge: this card already renders its own unconditional
  # "Applied" pill, so only the outcome tier belongs here. "offered" has no
  # entry in OUTCOME_BADGE_CLASSES -- this card has never shown an offer
  # badge (the original if/elsif had no branch for it either), so an
  # unmapped semantic renders nothing rather than raising.
  def outcome_badge(user_job)
    badge = Pipeline::DisplayStatus.outcome(user_job)
    return nil unless badge

    css = OUTCOME_BADGE_CLASSES[badge[:semantic]]
    return nil unless css

    [css, badge[:label]]
  end
end
