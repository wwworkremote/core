class AddStatusToJobPosting < ActiveRecord::Migration[8.0]
  def change
    add_column :job_postings, :status, :string
  end
end
