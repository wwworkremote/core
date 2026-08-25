# frozen_string_literal: true

# Pushes a toast to every open page when a JobRun transitions -- the "live
# notification" half of TASK-89. Kept separate from JobRun itself so the
# model stays a plain record; this is presentation, not persistence.
class JobRunBroadcaster
  def self.call(job_run)
    Turbo::StreamsChannel.broadcast_prepend_to("job_activity", **partial_options(job_run))
  end

  def self.partial_options(job_run)
    { target: "job_activity_toasts", partial: "job_runs/toast", locals: { job_run: job_run } }
  end
end
