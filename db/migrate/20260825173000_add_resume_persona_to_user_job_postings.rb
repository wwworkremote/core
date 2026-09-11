# frozen_string_literal: true

class AddResumePersonaToUserJobPostings < ActiveRecord::Migration[8.1]
  # rubocop:disable-next Metrics/MethodLength
  def change
    safety_assured do
      change_table :user_job_postings, bulk: true do |t|
        t.string :resume_persona_id
        t.jsonb :resume_persona_snapshot, null: false, default: {}
        t.jsonb :application_profile_snapshot, null: false, default: {}
      end
    end
  end
end
