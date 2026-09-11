# frozen_string_literal: true

# When the application actually happened, as distinct from when we learned
# about it. `created_at` is import time -- backfilling months of history in one
# afternoon collapses every real date onto today, which makes the funnel's
# staleness signal (TASK-81) fiction. Nullable because postings tracked before
# this column existed have no defensible date to assign.
class AddAppliedAtToUserJobPostings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :user_job_postings, :applied_at, :datetime
    add_index :user_job_postings, :applied_at, algorithm: :concurrently
  end
end
