# frozen_string_literal: true

class CreateJobRuns < ActiveRecord::Migration[8.1]
  # Column list is one cohesive table definition -- splitting it further
  # would obscure the schema, not simplify it.
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def change
    create_table :job_runs do |t|
      t.string :job_class, null: false
      t.string :active_job_id, null: false
      t.string :queue_name
      t.string :status, null: false, default: "running"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.text :error_message

      t.timestamps
    end

    add_index :job_runs, :active_job_id
    add_index :job_runs, %i[status created_at]
    add_index :job_runs, %i[job_class created_at]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
