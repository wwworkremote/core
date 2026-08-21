# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id             :bigint           not null, primary key
#  cover_letter   :text
#  match_analysis :text
#  match_score    :integer
#  match_tags     :text             default([]), not null, is an Array
#  notes          :text
#  priority_flag  :boolean
#  status         :string
#  strategy       :jsonb            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  job_search_id  :bigint
#  user_id        :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_job_posting_id  (job_posting_id)
#  index_user_job_postings_on_job_search_id   (job_search_id)
#  index_user_job_postings_on_match_score     (match_score)
#  index_user_job_postings_on_user_id         (user_id)
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

  aasm column: :status, whiny_persistence: true do
    state :none, initial: true
    state :favorited, :applied, :interview, :offered, :archived

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

    event :offer do
      transitions from: %i[favorited applied interview], to: :offered
    end

    event :archive do
      transitions from: %i[favorited applied interview offered], to: :archived
    end
  end

  STATUS_EVENTS = %w[favorite apply interview offer archive].freeze

  # The transitions legal from the current state. An unsaved record answers
  # for a posting the user hasn't tracked yet, so callers need no nil branch.
  def available_status_events
    STATUS_EVENTS.select { |event| send("may_#{event}?") }
  end

  # Applies an AASM event and logs it to the pipeline timeline, so a status
  # change made from the web UI and one made from the extension leave the same
  # trail. `link` records where it happened -- the extension passes the ATS
  # application URL, which is the one piece of context you can't reconstruct
  # later once the posting is taken down. Returns the logged PipelineStep, or
  # nil when the transition isn't legal -- callers get a no-op instead of an
  # AASM::InvalidTransition.
  def record_status_event!(event, link: nil)
    return unless STATUS_EVENTS.include?(event.to_s) && send("may_#{event}?")

    send("#{event}!")
    user.pipeline_steps.create!(job_posting: job_posting, status: event.to_s, link: link,
                                note: "User marked as #{event}")
  end
end
