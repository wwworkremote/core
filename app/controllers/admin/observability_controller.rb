# frozen_string_literal: true

module Admin
  class ObservabilityController < Admin::ApplicationController
    def index
      # Golden Signals
      @latency_avg = JobPosting.where.not(enriched_at: nil)
                               .average('enriched_at - created_at')
                               .to_f.round(2)
      
      @traffic_daily = Source.where(created_at: 24.hours.ago..).count
      
      @error_rate = (SolidQueue::Job.failed.count.to_f / [SolidQueue::Job.count, 1].max * 100).round(2)
      
      @saturation = (SolidQueue::Process.where(kind: 'Worker').count.to_f / [ENV.fetch("JOB_CONCURRENCY", 1).to_i, 1].max * 100).round(0)

      # Behavioral Intel (Ahoy)
      @total_visits = Ahoy::Visit.count
      @top_referrers = Ahoy::Visit.group(:referrer).order('count_all DESC').limit(5).count
      @top_job_searches = Ahoy::Event.where(name: 'Searched Jobs').group("properties->>'q'").order('count_all DESC').limit(5).count
    end
  end
end
