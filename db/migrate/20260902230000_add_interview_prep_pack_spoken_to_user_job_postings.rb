# frozen_string_literal: true

class AddInterviewPrepPackSpokenToUserJobPostings < ActiveRecord::Migration[8.1]
  def change
    add_column :user_job_postings, :interview_prep_pack_spoken, :text
  end
end
