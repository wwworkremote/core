# frozen_string_literal: true

# Turns InterviewSession from a flat log into an ordered pipeline:
# `position` sequences the rounds, `outcome` records how each round went
# (pending / advanced / rejected / no_signal), `interviewers` is a free-text
# note of who was in the room. See TASK-147.1.
class AddSequenceFieldsToInterviewSessions < ActiveRecord::Migration[8.1]
  def change
    # rubocop:disable Rails/BulkChangeTable -- strong_migrations can't safety-check inside change_table
    add_column :interview_sessions, :position, :integer
    add_column :interview_sessions, :outcome, :string, null: false, default: "pending"
    add_column :interview_sessions, :interviewers, :string
    # rubocop:enable Rails/BulkChangeTable
  end
end
