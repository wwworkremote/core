# frozen_string_literal: true

# What the *employer* did, kept separate from `status`, which is what Mike did.
#
# Conflating the two loses the distinction that matters most when reading a
# funnel: "applied and heard nothing" and "applied and was rejected" are the
# same AASM state but completely different facts about the search. Folding a
# rejection into `archived` would also destroy it -- archived is a filing
# action, not an outcome.
#
# Nullable and unconstrained by design: outcome vocabulary differs per source
# (Indeed says REVIEWED/REJECTED, Greenhouse exposes stages some employers
# don't share), and normalizing too early would throw away signal we can't get
# back. `outcome_source` records who said so.
class AddOutcomeToUserJobPostings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # rubocop:disable Rails/BulkChangeTable -- the concurrent index can't run
  # inside change_table :bulk, and strong_migrations can't safety-check there.
  def change
    add_column :user_job_postings, :outcome, :string
    add_column :user_job_postings, :outcome_at, :datetime
    add_column :user_job_postings, :outcome_source, :string
    add_index :user_job_postings, :outcome, algorithm: :concurrently
  end
  # rubocop:enable Rails/BulkChangeTable
end
