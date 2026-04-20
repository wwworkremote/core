class AddPriorityFlagToUserJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :user_job_postings, :priority_flag, :boolean
  end
end
