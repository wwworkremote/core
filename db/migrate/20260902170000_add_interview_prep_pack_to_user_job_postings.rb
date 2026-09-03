# frozen_string_literal: true

class AddInterviewPrepPackToUserJobPostings < ActiveRecord::Migration[8.1]
  # rubocop:disable-next Metrics/MethodLength
  def change
    safety_assured do
      change_table :user_job_postings, bulk: true do |t|
        t.text :interview_prep_pack
        t.datetime :interview_prep_pack_generated_at
      end
    end
  end
end
