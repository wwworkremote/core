# frozen_string_literal: true

# The expected sequence of interview rounds for a hiring process, materialized
# as InterviewSession placeholder rows (no scheduled_at yet -- Mike fills the
# dates in as rounds get booked). Not a model and not a table: one user, a
# handful of known process shapes, so the templates are a frozen constant.
#
# Templates derive from the "normal SWE hiring pipeline" reference in
# TASK-147.1. session_type stays within InterviewSession::SESSION_TYPES; the
# finer-grained stage name rides along in `notes`.
module InterviewProcess
  def self.round(session_type, notes)
    { session_type: session_type, notes: notes }
  end

  TEMPLATES = {
    # Full mid-size-to-large IC loop.
    standard_senior: [
      round("Screening", "Recruiter screen"),
      round("Screening", "Hiring manager screen"),
      round("Technical", "Technical screen"),
      round("Technical", "Onsite: coding"),
      round("System_Design", "Onsite: system design"),
      round("Cultural", "Onsite: behavioral"),
      round("Offer_Negotiation", "Offer & negotiation")
    ],
    # Startup / smaller ad-tech: fewer rounds, a founder/VP conversation
    # instead of a full committee loop.
    compressed: [
      round("Screening", "Recruiter screen"),
      round("Screening", "Hiring manager screen"),
      round("Technical", "Technical screen"),
      round("System_Design", "Onsite (2-3 interviewers)"),
      round("Management", "VP / founder conversation"),
      round("Offer_Negotiation", "Offer & negotiation")
    ],
    # Staff/Principal: standard_senior plus architecture depth, an influence
    # round, a project presentation, and a skip-level.
    staff: [
      round("Screening", "Recruiter screen"),
      round("Screening", "Hiring manager screen"),
      round("Technical", "Technical screen"),
      round("Technical", "Onsite: coding"),
      round("System_Design", "Onsite: system design"),
      round("System_Design", "Architecture deep-dive"),
      round("Cultural", "Project presentation"),
      round("Management", "Cross-functional / influence"),
      round("Management", "Skip-level / director"),
      round("Offer_Negotiation", "Offer & negotiation")
    ]
  }.freeze

  TEMPLATE_NAMES = TEMPLATES.keys.freeze

  # One in-flight interview process, as the homepage needs it: which round is
  # next, how far along it is, and the next thing to do before that round.
  Progress = Data.define(:posting, :current, :position, :total, :next_task)

  # The in-flight interview processes for `user`: one Progress per posting that
  # still has a pending round. Insertion order follows InterviewSession.ordered
  # (position, then scheduled_at).
  def self.in_flight_for(user)
    tasks = user.interview_tasks.where(status: "pending").order(:due_at).group_by(&:job_posting_id)
    rounds_by_posting(user).filter_map { |posting, rounds| progress(posting, rounds, tasks) }
  end

  def self.rounds_by_posting(user)
    user.interview_sessions.includes(:job_posting).ordered.group_by(&:job_posting)
  end

  def self.progress(posting, rounds, tasks_by_posting)
    current = rounds.find(&:pending?)
    return unless current

    Progress.new(posting: posting, current: current, position: rounds.index(current) + 1,
                 total: rounds.size, next_task: tasks_by_posting[posting.id]&.first)
  end

  def self.rounds_for(template)
    TEMPLATES.fetch(template.to_sym) { raise ArgumentError, "unknown template #{template.inspect}" }
  end

  def self.already_seeded?(user_job_posting)
    user_job_posting.job_posting.interview_sessions.exists?(user: user_job_posting.user)
  end

  # Materialize `template`'s rounds as InterviewSession rows for the posting
  # behind `user_job_posting`. No-op (returns []) when that posting already
  # has sessions for this user -- seeding twice would double the sequence.
  # Returns the created sessions in order.
  def self.seed_default(user_job_posting, template: :standard_senior)
    return [] if already_seeded?(user_job_posting)

    rounds_for(template).map.with_index(1) { |round, position| create_round(user_job_posting, round, position) }
  end

  def self.create_round(user_job_posting, round, position)
    user_job_posting.job_posting.interview_sessions.create!(
      round.merge(user: user_job_posting.user, position: position)
    )
  end
end
