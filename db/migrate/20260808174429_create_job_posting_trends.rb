# frozen_string_literal: true

# rubocop:disable-next Metrics/MethodLength
class CreateJobPostingTrends < ActiveRecord::Migration[8.1]
  def change
    create_table :job_posting_trends do |t|
      t.date :week_start, null: false
      t.string :role_family, null: false
      t.integer :postings_count, null: false, default: 0
      t.timestamps
    end

    add_index :job_posting_trends, %i[week_start role_family], unique: true,
                                                               name: "index_job_posting_trends_on_week_and_family"
  end
end
