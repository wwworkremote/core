# frozen_string_literal: true

#
# Trace one JobPosting's downstream pipeline (Categorizer, Embedder,
# GeocodingJob, StrategyJob, ProfileMatchJob) after a promote/scrape. Run
# with:
#   bin/rails runner .claude/skills/pipeline-health/scripts/job_posting_pipeline_status.rb 5061 5060
#
# SolidQueue prunes finished job rows quickly on this box, so this is only
# reliable for jobs that finished in the last few hours -- absence of a
# SolidQueue::Job row does NOT mean the job never ran, check the JobPosting's
# own fields (data["ai_category"], embedding, latitude/longitude) as the
# source of truth for whether the pipeline actually completed. Makes no
# writes.

DOWNSTREAM_CLASSES = %w[
  JobBoards::AnalysisJob JobBoards::StrategyJob LLM::ProfileMatchJob JobBoards::GeocodingJob
].freeze

def section(title)
  puts "\n=== #{title} ==="
  yield
end

ids = ARGV.map(&:to_i)
abort "usage: bin/rails runner .../job_posting_pipeline_status.rb <job_posting_id> [id...]" if ids.empty?

JobPosting.where(id: ids).order(:id).each do |jp|
  section("JobPosting #{jp.id}: #{jp.title}") do
    puts "ai_category:  #{jp.data['ai_category'].inspect}"
    puts "embedding:    #{jp.embedding.present? ? "present (#{jp.embedding.size} dims)" : 'nil'}"
    puts "lat/lng:      #{[jp.latitude, jp.longitude].inspect}"
    puts "updated_at:   #{jp.updated_at}"
  end
end

section("Matching SolidQueue::Job rows (last 3h, may be pruned for older runs)") do
  DOWNSTREAM_CLASSES.each do |cls|
    SolidQueue::Job.where(class_name: cls).where(created_at: 3.hours.ago..).find_each do |j|
      args = j.arguments["arguments"] rescue []
      hit = args.find { |a| ids.include?(a) }
      next unless hit

      puts "#{cls} job_posting=#{hit} job_id=#{j.id} finished_at=#{j.finished_at || 'PENDING'}"
    end
  end
rescue NameError
  puts "SolidQueue not present in this app"
end

section("FailedExecutions on these classes (any age)") do
  SolidQueue::FailedExecution.joins(:job)
                             .where("solid_queue_jobs.class_name" => DOWNSTREAM_CLASSES + %w[JobBoards::Categorizer JobBoards::Embedder])
                             .order(id: :desc).limit(10).each do |f|
    puts "#{f.job.class_name} job=#{f.job_id}: #{(f.error['message'] rescue f.error).to_s[0, 160]}"
  end
rescue NameError
  puts "n/a"
end
