# frozen_string_literal: true

class JobPostingTrend < ApplicationRecord
  def self.weekly_breakdown(week_start)
    where(week_start: week_start.to_date.beginning_of_week).pluck(:role_family, :postings_count).to_h
  end
end
