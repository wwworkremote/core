# frozen_string_literal: true

# == Schema Information
#
# Table name: job_posting_trends
#
#  id             :bigint           not null, primary key
#  postings_count :integer          default(0), not null
#  role_family    :string           not null
#  week_start     :date             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_job_posting_trends_on_week_and_family  (week_start,role_family) UNIQUE
#
class JobPostingTrend < ApplicationRecord
  def self.weekly_breakdown(week_start)
    where(week_start: week_start.to_date.beginning_of_week).pluck(:role_family, :postings_count).to_h
  end
end
