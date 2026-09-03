# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id                               :bigint           not null, primary key
#  application_profile_snapshot     :jsonb            not null
#  applied_at                       :datetime
#  cover_letter                     :text
#  interview_prep_pack              :text
#  interview_prep_pack_generated_at :datetime
#  interview_prep_pack_spoken       :text
#  match_analysis                   :text
#  match_score                      :integer
#  match_tags                       :text             default([]), not null, is an Array
#  notes                            :text
#  outcome                          :string
#  outcome_at                       :datetime
#  outcome_reason                   :text
#  outcome_source                   :string
#  priority_flag                    :boolean
#  resume_persona_snapshot          :jsonb            not null
#  status                           :string
#  strategy                         :jsonb            not null
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  application_trace_id             :string
#  job_posting_id                   :bigint           not null
#  job_search_id                    :bigint
#  resume_persona_id                :string
#  user_id                          :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_application_trace_id  (application_trace_id)
#  index_user_job_postings_on_applied_at            (applied_at)
#  index_user_job_postings_on_job_posting_id        (job_posting_id)
#  index_user_job_postings_on_job_search_id         (job_search_id)
#  index_user_job_postings_on_match_score           (match_score)
#  index_user_job_postings_on_outcome               (outcome)
#  index_user_job_postings_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (job_search_id => job_searches.id)
#  fk_rails_...  (user_id => users.id)
#
class UserJobPosting < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :job_posting
  belongs_to :job_search, optional: true

  # Set only when a Scenario (a deliberately recorded verification capture,
  # see docs/architecture/signature-registry.md) turns out to correspond to
  # this real tracked application. Most UserJobPostings have none.
  has_many :scenarios, dependent: :nullify

  # TASK-91.1: the rejection email/screenshot, kept as evidence alongside
  # outcome_reason. Generic on the model (any outcome could attach one) --
  # the UI only exposes it on the Reject flow, see job_postings/show.html.erb.
  has_one_attached :outcome_evidence

  has_many :application_field_answers, dependent: :destroy
  has_many :application_field_mappings, dependent: :destroy
  has_many :application_field_observations, dependent: :destroy

  # Guided supervised laps started from this posting (ADR 010 entry seam).
  # nullify, not destroy -- a session's recorded evidence outlives the
  # UserJobPosting, same as scenarios above.
  has_many :guided_sessions, dependent: :nullify

  # `offered` deliberately isn't a status here -- it's the employer's
  # decision, the same kind of fact as outcome's `rejected`, not a stage
  # Mike walks through like `applied`/`interview` are (TASK-82/TASK-94).
  # Marking an offer goes through the outcome column instead; see
  # UserJobPostingsController::MANUAL_OUTCOMES.
  aasm column: :status, whiny_persistence: true do
    state :none, initial: true
    state :favorited, :applied, :interview, :archived

    event :favorite do
      transitions from: %i[none archived], to: :favorited
    end

    # `none` is a valid origin: applying directly from a board (or from the
    # Chrome extension while sitting on the application page) is the common
    # path, and requiring a favorite first made `applied` unreachable.
    event :apply do
      transitions from: %i[none favorited interview], to: :applied
    end

    event :interview do
      transitions from: %i[favorited applied], to: :interview
    end

    # :none is a valid origin -- the admin UI's Application Status card lets
    # Mike archive a posting he's never favorited/applied to, to dismiss it
    # without going through the rest of the pipeline first. JobPosting's own
    # archive event allowed this too before TASK-82 phase 3 moved archiving
    # off JobPosting, so this preserves the same reachable behavior.
    event :archive do
      transitions from: %i[none favorited applied interview], to: :archived
    end
  end

  STATUS_EVENTS = %w[favorite apply interview archive].freeze

  # "Processed through the harness" (ADR 010 / TASK-125): a tracked
  # application with at least one completed guided session. One definition,
  # reused wherever the count appears.
  scope :processed_through_harness, -> { where(id: GuidedSession.completed.select(:user_job_posting_id)) }

  HARNESS_STATES = %i[none in_progress recorded compared].freeze

  # Furthest-reached harness state across this application's guided sessions.
  # Advisory/read-only -- never affects pipeline status.
  def harness_state
    return :compared if guided_sessions.joins(:reference_comparisons).exists?
    return :recorded if harness_recorded?
    return :in_progress if guided_sessions.in_flight.exists?

    :none
  end

  def harness_recorded?
    guided_sessions.completed.where.not(scenario_id: nil).exists?
  end

  # The read-aloud pack opens with a YAML frontmatter block fenced by "---".
  # Returns [hints_hash, body] so the view can surface the read-aloud hints
  # and markdown-render the body without a stray horizontal rule.
  def spoken_pack_parts
    m = interview_prep_pack_spoken.to_s.match(/\A---\s*\n(?<fm>.*?)\n---\s*\n(?<body>.*)\z/m)
    m ? [parse_frontmatter(m[:fm]), m[:body]] : [{}, interview_prep_pack_spoken.to_s]
  end

  def parse_frontmatter(text)
    parsed = YAML.safe_load(text, permitted_classes: [], aliases: false)
    parsed.is_a?(Hash) ? parsed : {}
  rescue Psych::SyntaxError
    {}
  end

  # TASK-93: "actively pursuing, gone quiet." archived/none excluded --
  # archived means Mike stopped, none means he never started.
  ACTIVE_STATUSES = %w[favorited applied interview].freeze
  TERMINAL_OUTCOMES = %w[offered rejected].freeze
  IDLE_AFTER = 3.days

  # Mirrors #last_pipeline_activity_at's fallback (see there for why a
  # COALESCE to created_at is needed, not just MAX(pipeline_steps.created_at))
  # -- shared as one fragment so the .idle scope's WHERE and ORDER BY can't
  # drift from what that method actually returns.
  LAST_ACTIVITY_SQL = <<~SQL.squish.freeze
    COALESCE(
      (SELECT MAX(ps.created_at) FROM pipeline_steps ps
       WHERE ps.job_posting_id = user_job_postings.job_posting_id
       AND ps.user_id = user_job_postings.user_id),
      user_job_postings.created_at
    )
  SQL

  # "outcome IS NULL OR outcome NOT IN (...)" rather than where.not(outcome:
  # ...) -- SQL's NOT IN silently excludes NULLs, and outcome is nil for
  # nearly every actively-tracked posting (only set once a manual/imported
  # outcome lands). where.not would have quietly matched almost nothing.
  # Same reasoning for job_postings.status. Excludes JobPosting-side
  # archived/expired too (a dead link or auto-expiry isn't something to nag
  # Mike about following up on).
  scope :idle, lambda {
    where(status: ACTIVE_STATUSES)
      .where("outcome IS NULL OR outcome NOT IN (?)", TERMINAL_OUTCOMES)
      .joins(:job_posting)
      .where("job_postings.status IS NULL OR job_postings.status NOT IN (?)", %w[archived expired])
      .where("#{LAST_ACTIVITY_SQL} < ?", IDLE_AFTER.ago)
      .order(Arel.sql("#{LAST_ACTIVITY_SQL} ASC"))
  }

  # Falls back to created_at, never nil -- the live UI always logs a
  # PipelineStep on every status change (record_status_event!/
  # advance_pipeline_state!), but the backfill importers
  # (bin/import_indeed_applications, bin/import_linkedin_tracker) write
  # status directly and don't, so an imported row can have none at all.
  # created_at is still the honest answer to "since when has this sat
  # untouched" for that row -- and matches what makes it count as idle in
  # the first place (see LAST_ACTIVITY_SQL above).
  def last_pipeline_activity_at
    PipelineStep.where(job_posting_id: job_posting_id, user_id: user_id).maximum(:created_at) || created_at
  end

  # The transitions legal from the current state. An unsaved record answers
  # for a posting the user hasn't tracked yet, so callers need no nil branch.
  def available_status_events
    STATUS_EVENTS.select { |event| send("may_#{event}?") }
  end

  # Guarded AASM transition with no side effect beyond the state change --
  # split out of record_status_event! so a caller that already logs its own
  # richer PipelineStep (e.g. Admin::PipelineStepsController, which captures
  # triage reason_tags that this model knows nothing about) can keep
  # UserJobPosting.status in sync without also getting a second, plainer
  # PipelineStep row for the same click. Returns the AASM event's own truthy
  # result on success, nil on a no-op -- same "no exception, just falsy"
  # contract record_status_event! already gives every other caller.
  def advance_pipeline_state!(event)
    return unless STATUS_EVENTS.include?(event.to_s) && send("may_#{event}?")

    send("#{event}!")
  end

  # Applies an AASM event and logs it to the pipeline timeline, so a status
  # change made from the web UI and one made from the extension leave the same
  # trail. `link` records where it happened -- the extension passes the ATS
  # application URL, which is the one piece of context you can't reconstruct
  # later once the posting is taken down. Returns the logged PipelineStep, or
  # nil when the transition isn't legal -- callers get a no-op instead of an
  # AASM::InvalidTransition.
  def record_status_event!(event, link: nil)
    return unless advance_pipeline_state!(event)

    user.pipeline_steps.create!(job_posting: job_posting, status: event.to_s, link: link,
                                note: "User marked as #{event}")
  end
end
