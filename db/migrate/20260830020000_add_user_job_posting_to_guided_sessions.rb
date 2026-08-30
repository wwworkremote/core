# frozen_string_literal: true

# Entry seam (ADR 010 §1): a guided session started from a job posting is linked
# to the tracked application. Nullable -- a verification-only or ad-hoc session
# still has none, exactly as scenarios.user_job_posting_id is nullable.
class AddUserJobPostingToGuidedSessions < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      add_reference :guided_sessions, :user_job_posting, null: true, foreign_key: true, index: true
    end
  end
end
