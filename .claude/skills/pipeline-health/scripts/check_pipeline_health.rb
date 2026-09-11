# frozen_string_literal: true

#
# Read-only pipeline health snapshot. Run with:
#   bin/rails runner .claude/skills/pipeline-health/scripts/check_pipeline_health.rb
#
# Prints ingestion volume, SolidQueue backlog/failure breakdown, recent error
# samples per failing job class, and the recurring task schedule. Makes no
# writes.

def section(title)
  puts "\n=== #{title} ==="
  yield
end

section("Ingestion volume") do
  puts "job_postings total: #{JobPosting.count}"
  puts "created last 24h: #{JobPosting.where(created_at: 24.hours.ago..).count}"
  puts "created last 7d:   #{JobPosting.where(created_at: 7.days.ago..).count}"
  puts "most recent:       #{JobPosting.maximum(:created_at) || 'none'}"
end

section("Sources") do
  puts "job_boards_sources: #{JobBoards::Source.count}"
end

section("SolidQueue backlog") do
  pending = SolidQueue::Job.where(finished_at: nil).count
  failed = SolidQueue::FailedExecution.count
  finished_24h = SolidQueue::Job.where(finished_at: 24.hours.ago..).count
  created_24h = SolidQueue::Job.where(created_at: 24.hours.ago..).count
  puts "pending jobs:              #{pending}"
  puts "unresolved failed executions: #{failed}"
  puts "finished last 24h:         #{finished_24h}"
  puts "created last 24h:          #{created_24h}"
rescue NameError
  puts "SolidQueue not present in this app"
end

section("Failed jobs by class") do
  SolidQueue::FailedExecution.joins(:job)
                             .group("solid_queue_jobs.class_name")
                             .count
                             .sort_by { |_, v| -v }
                             .each { |klass, count| puts "#{count}\t#{klass}" }
rescue NameError
  puts "n/a"
end

section("One recent error sample per failing job class") do
  classes = SolidQueue::FailedExecution.joins(:job).distinct.pluck("solid_queue_jobs.class_name")
  classes.each do |klass|
    fe = SolidQueue::FailedExecution.joins(:job)
                                    .where("solid_queue_jobs.class_name" => klass)
                                    .order(created_at: :desc)
                                    .first
    err = fe.error
    msg = err.is_a?(Hash) ? (err["message"] || err[:message]) : err.to_s
    exception_class = err.is_a?(Hash) ? err["exception_class"] : nil
    tag =
      case msg.to_s
      when /uninitialized constant/, /NoMethodError/, /NameError/
        "CODE BUG"
      when /ProcessPrunedError|process was found dead/i
        "WORKER/INFRA (heartbeat timeout, likely OOM or long-running job)"
      else
        "INVESTIGATE"
      end
    puts "[#{tag}] #{klass} (#{exception_class}): #{msg.to_s[0, 160]}"
  end
rescue NameError
  puts "n/a"
end

section("Recurring task schedule") do
  SolidQueue::RecurringTask.find_each { |t| puts "#{t.key}: #{t.schedule}" }
rescue StandardError => e
  puts "n/a (#{e.message})"
end
