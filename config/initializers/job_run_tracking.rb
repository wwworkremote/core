# frozen_string_literal: true

# Logs every ActiveJob execution's start/finish/error to JobRun (a durable
# table SolidQueue itself doesn't provide -- it prunes finished job rows
# hourly and never records a start time) and broadcasts a Turbo Stream toast
# so the running app shows job activity live. See TASK-89.
module JobRunTracking
  # SolidCable's ActionCable adapter runs ::SolidCable::TrimJob.perform_now
  # inline on every broadcast (lib/action_cable/subscription_adapter/solid_cable.rb).
  # Tracking it would mean each JobRun broadcast triggers a cable message,
  # which triggers TrimJob, which -- if tracked -- broadcasts again: infinite
  # recursion (SystemStackError). Excluded as plumbing, not pipeline activity.
  EXCLUDED_CLASSES = ["SolidCable::TrimJob"].freeze

  def self.job_identity(event)
    job = event.payload[:job]
    { job_class: job.class.name, active_job_id: job.job_id, queue_name: job.queue_name }
  end

  ActiveSupport::Notifications.subscribe("perform_start.active_job") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    next if EXCLUDED_CLASSES.include?(event.payload[:job].class.name)

    job_run = JobRun.create!(job_identity(event).merge(status: "running", started_at: Time.current))
    JobRunBroadcaster.call(job_run)
  end

  ActiveSupport::Notifications.subscribe("perform.active_job") do |*args|
    event = ActiveSupport::Notifications::Event.new(*args)
    next if EXCLUDED_CLASSES.include?(event.payload[:job].class.name)

    job_run = JobRun.find_by(active_job_id: event.payload[:job].job_id)
    next unless job_run

    exception = event.payload[:exception_object]
    job_run.update!(
      status: exception ? "failed" : "finished",
      finished_at: Time.current,
      error_message: exception&.message
    )
    JobRunBroadcaster.call(job_run)
  end
end
