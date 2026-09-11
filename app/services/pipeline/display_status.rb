# frozen_string_literal: true

# Reconciles the pipeline/status cluster's three independent status
# vocabularies -- JobPosting's lifecycle AASM (JobPosting::StatusWorkflow),
# UserJobPosting's outcome string, and UserJobPosting's pipeline AASM --
# into one badge decision, so no caller has to know the precedence rule
# itself. See TASK-82 for why these three stay separate models rather than
# merging: JobPosting-status is a fact about the listing, UserJobPosting-
# status is Mike's own pipeline stage, outcome is the employer's response.
#
# Returns a semantic key, not CSS -- callers render their own badge markup
# (job_postings/show.html.erb and user_job_postings/index.html.erb use
# different visual idioms for the same concept, and this module has no
# opinion on either).
class Pipeline::DisplayStatus
  LIFECYCLE = {
    "archived" => { label: "Archived", semantic: :lifecycle_archived },
    "ignored" => { label: "Not Interested", semantic: :lifecycle_ignored },
    "expired" => { label: "Expired", semantic: :lifecycle_expired },
    "purged" => { label: "Purged", semantic: :lifecycle_purged }
  }.freeze

  OUTCOME = {
    "offered" => { label: "Offered", semantic: :outcome_offered },
    "rejected" => { label: "Rejected", semantic: :outcome_rejected },
    "reviewed" => { label: "Reviewed", semantic: :outcome_reviewed },
    "closed" => { label: "Posting closed", semantic: :outcome_closed }
  }.freeze

  PIPELINE = {
    "favorited" => { label: "Favorited", semantic: :pipeline_favorited },
    "applied" => { label: "Applied", semantic: :pipeline_applied },
    "interview" => { label: "Interviewing", semantic: :pipeline_interview },
    "archived" => { label: "Archived", semantic: :pipeline_archived }
  }.freeze

  # JobPosting's own archived wins over UserJobPosting's archived -- a dead
  # link outranks an old pipeline decision as the more current fact.
  def self.call(job_posting:, user_job:)
    LIFECYCLE[job_posting.status] || OUTCOME[user_job&.outcome] || PIPELINE[user_job&.status]
  end

  def self.outcome(user_job)
    OUTCOME[user_job&.outcome]
  end
end
