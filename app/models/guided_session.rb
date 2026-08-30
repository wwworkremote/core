# frozen_string_literal: true

# A durable supervised lap through the job-posting-to-application pump track.
# The initial intake slice records where the lap started and leaves all
# provider interaction behind the existing extension seam.
# == Schema Information
#
# Table name: guided_sessions
#
#  id                  :bigint           not null, primary key
#  phase               :string           default("intake"), not null
#  playback_position   :integer          default(0), not null
#  provider            :string           not null
#  purpose             :string           default("application_execution"), not null
#  session_token       :string           not null
#  source_url          :string           not null
#  started_at          :datetime         not null
#  status              :string           default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  scenario_id         :bigint
#  user_job_posting_id :bigint
#
# Indexes
#
#  index_guided_sessions_on_scenario_id          (scenario_id)
#  index_guided_sessions_on_session_token        (session_token) UNIQUE
#  index_guided_sessions_on_user_job_posting_id  (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (scenario_id => scenarios.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
class GuidedSession < ApplicationRecord
  PHASES = %w[intake resolution response_construction reorientation].freeze
  PURPOSES = %w[application_research application_execution].freeze
  STATUSES = %w[active paused completed stopped].freeze

  has_secure_token :session_token
  has_many :guided_session_events, dependent: :destroy
  has_many :reference_comparisons, dependent: :destroy
  has_many :guided_session_replays, dependent: :destroy
  # Set once the session is materialized for Reference Comparison (ADR 009).
  belongs_to :scenario, optional: true
  # Entry seam (ADR 010): set when the session was started from a job posting.
  # Nullable -- a verification-only or ad-hoc session has none.
  belongs_to :user_job_posting, optional: true

  validates :source_url, :provider, :phase, :status, :started_at, presence: true
  validates :phase, inclusion: { in: PHASES }
  validates :purpose, inclusion: { in: PURPOSES }
  validates :status, inclusion: { in: STATUSES }
  validates :playback_position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :source_url_is_http

  scope :completed, -> { where(status: "completed") }
  scope :in_flight, -> { where(status: %w[active paused]) }

  before_validation :set_intake_attributes, on: :create

  # First transition to completed triggers one automatic Reference Comparison
  # (ADR 009). Advisory only -- a comparison failure never blocks completion,
  # and this never touches phase or playback_position.
  def complete!
    return if status == "completed"

    update!(status: "completed")
    propose_application_transition
    run_automatic_comparison
  end

  def latest_comparison
    reference_comparisons.order(:ran_at, :id).last
  end

  def tracked_source_url
    uri = parsed_source_url
    uri.query = tracked_query(uri)
    uri.to_s
  end

  private

  def run_automatic_comparison
    return if reference_comparisons.exists?(trigger: "automatic")

    Scenarios::RecordComparison.call(self, trigger: "automatic")
  rescue StandardError => e
    Rails.logger.warn "[GuidedSession] automatic comparison failed: #{e.class}: #{e.message}"
  end

  # Completion may *propose* the implied UserJobPosting transition as a
  # HumanTask -- it never applies it (Bounded Agency, ADR 010 §1). Idempotent
  # on (job_posting, user, kind, pending) so a re-complete raises nothing new.
  def propose_application_transition
    return unless user_job_posting&.may_apply?

    HumanTask.propose_apply(user_job_posting, session_token)
  rescue StandardError => e
    Rails.logger.warn "[GuidedSession] transition proposal failed: #{e.class}: #{e.message}"
  end

  def set_intake_attributes
    self.attributes = default_attributes.merge(provider: provider || source_uri_host)
  end

  def default_attributes
    { started_at: started_at || Time.current,
      phase: phase || "intake",
      status: status || "active" }
  end

  def source_url_is_http
    uri = parsed_source_url
    return errors.add(:source_url, "must be a valid HTTP or HTTPS URL") unless uri&.host
    return if %w[http https].include?(uri.scheme)

    errors.add(:source_url, "must be a valid HTTP or HTTPS URL")
  end

  def parsed_source_url
    URI.parse(source_url.to_s)
  rescue URI::InvalidURIError
    nil
  end

  # Carries the correlation token and the session purpose onto the employer
  # URL. content.js reads guided_session_purpose to decide whether to run the
  # chrome.debugger HAR / full-page path (TASK-134) or just the light path.
  def tracked_query(uri)
    URI.encode_www_form(existing_params(uri).merge(carried_params))
  end

  def existing_params(uri)
    URI.decode_www_form(uri.query.to_s).to_h.except(*carried_params.keys)
  end

  def carried_params
    @carried_params ||= { "guided_session_token" => session_token, "guided_session_purpose" => purpose }
  end

  def source_uri_host
    parsed_source_url&.host&.downcase
  end
end
