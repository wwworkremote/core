# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id                           :bigint           not null, primary key
#  application_profile_snapshot :jsonb            not null
#  applied_at                   :datetime
#  cover_letter                 :text
#  match_analysis               :text
#  match_score                  :integer
#  match_tags                   :text             default([]), not null, is an Array
#  notes                        :text
#  outcome                      :string
#  outcome_at                   :datetime
#  outcome_source               :string
#  priority_flag                :boolean
#  resume_persona_snapshot      :jsonb            not null
#  status                       :string
#  strategy                     :jsonb            not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  application_trace_id         :string
#  job_posting_id               :bigint           not null
#  job_search_id                :bigint
#  resume_persona_id            :string
#  user_id                      :bigint           not null
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

  has_many :application_field_answers, dependent: :destroy
  has_many :application_field_mappings, dependent: :destroy
  has_many :application_field_observations, dependent: :destroy

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
