# frozen_string_literal: true

class Admin::ObservabilityController < Admin::ApplicationController
  def index
    assign_golden_signals
    assign_behavioral_intel
  end

  private

  def assign_golden_signals
    @latency_avg = average_enrichment_latency
    @traffic_daily = Source.where(created_at: 24.hours.ago..).count
    @error_rate = solid_queue_error_rate
    @saturation = worker_saturation
  end

  def average_enrichment_latency
    JobPosting.where.not(enriched_at: nil)
              .average("enriched_at - created_at")
              .to_f.round(2)
  end

  def solid_queue_error_rate
    (SolidQueue::Job.failed.count.to_f / [SolidQueue::Job.count, 1].max * 100).round(2)
  end

  def worker_saturation
    workers = SolidQueue::Process.where(kind: "Worker").count.to_f
    configured = [ENV.fetch("JOB_CONCURRENCY", 1).to_i, 1].max
    (workers / configured * 100).round(0)
  end

  def assign_behavioral_intel
    @total_visits = Ahoy::Visit.count
    @top_referrers = Ahoy::Visit.group(:referrer).order(count_all: :desc).limit(5).count
    @top_job_searches = top_job_search_terms
  end

  def top_job_search_terms
    Ahoy::Event.where(name: "Searched Jobs")
               .group("properties->>'q'")
               .order(count_all: :desc)
               .limit(5)
               .count
  end
end
