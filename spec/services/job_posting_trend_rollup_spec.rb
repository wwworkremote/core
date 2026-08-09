# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPostingTrendRollup do
  describe ".call" do
    it "buckets postings by week and role family" do
      week_one = Date.new(2026, 1, 5)
      week_two = Date.new(2026, 1, 12)
      create(:job_posting, title: "Staff Software Engineer", created_at: week_one.to_time)
      create(:job_posting, title: "Engineering Manager, Platform", created_at: week_one.to_time)
      create(:job_posting, title: "Staff Software Engineer", created_at: week_two.to_time)
      create(:job_posting, title: "Senior Software Engineer", created_at: week_two.to_time)

      described_class.call

      expect(JobPostingTrend.weekly_breakdown(week_one)).to eq(
        "staff_plus_ic" => 1, "engineering_management" => 1
      )
      expect(JobPostingTrend.weekly_breakdown(week_two)).to eq(
        "staff_plus_ic" => 1, "uncategorized" => 1
      )
    end

    it "updates existing rows on re-run instead of duplicating them" do
      week = Date.new(2026, 1, 5)
      create(:job_posting, title: "Staff Software Engineer", created_at: week.to_time)

      described_class.call
      create(:job_posting, title: "Principal Engineer", created_at: week.to_time)
      described_class.call

      expect(JobPostingTrend.weekly_breakdown(week)).to eq("staff_plus_ic" => 2)
      expect(JobPostingTrend.where(week_start: week.beginning_of_week, role_family: "staff_plus_ic").count).to eq(1)
    end
  end
end
