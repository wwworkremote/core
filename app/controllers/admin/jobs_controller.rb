# frozen_string_literal: true

class Admin::JobsController < Admin::ApplicationController
  def index
    dashboard = Dashboard.call
    assign_dashboard_ivars(dashboard)
  end

  def trigger
    task_id = params[:task_id]
    env_config = recurring_task_config
    return unauthorized_task(task_id) unless env_config.key?(task_id)

    execute_task(task_id, env_config[task_id])
    redirect_to admin_jobs_path
  end

  def prune
    count = SolidQueue::Process.prunable.count
    SolidQueue::Process.prunable.each(&:deregister)
    flash[:notice] = "🚀 Pruned #{count} dead processes."
    redirect_to admin_jobs_path
  end

  def details
    @job = SolidQueue::Job.find(params.expect(:id))
    render layout: false
  end

  def discard
    with_job_action_handling("discard") do
      @job = SolidQueue::Job.find(params.expect(:id))
      discard_job!
      flash[:notice] = "🚀 Job ##{@job.id} terminated and discarded."
    end
  end

  def cancel
    with_job_action_handling("cancel") do
      @job = SolidQueue::Job.find(params.expect(:id))
      cancel_and_discard_job!
      flash[:notice] = "🚀 Job ##{@job.id} signalled for mid-performance cancellation and discarded."
    end
  end

  private

  def with_job_action_handling(action)
    yield
  rescue StandardError => e
    flash_job_action_failure(action, e)
  ensure
    redirect_to admin_jobs_path
  end

  # If the job is claimed (in progress), remove the claim record first to
  # satisfy Solid Queue's integrity checks for discarding.
  def discard_job!
    SolidQueue::ClaimedExecution.where(job_id: @job.id).destroy_all
    @job.discard
  end

  def cancel_and_discard_job!
    SystemSetting.cancel_job!(@job.active_job_id)
    discard_job!
  end

  def flash_job_action_failure(action, error)
    flash[:alert] = job_action_failure_message(action, error)
  end

  def job_action_failure_message(action, error)
    return "Job not found." if error.is_a?(ActiveRecord::RecordNotFound)

    "Failed to #{action}: #{error.message}"
  end

  def assign_dashboard_ivars(dashboard)
    dashboard.instance_variables.each do |ivar|
      instance_variable_set(ivar, dashboard.instance_variable_get(ivar))
    end
  end

  def recurring_task_config
    all_configs = YAML.load_file(Rails.root.join("config/recurring.yml"))
    all_configs[Rails.env] || all_configs["development"]
  end

  def unauthorized_task(task_id)
    flash[:alert] = "Unauthorized or invalid task ID: #{task_id}"
    redirect_to admin_jobs_path
  end

  def execute_task(task_id, config)
    return flash[:alert] = "Task configuration not found for #{task_id} in #{Rails.env}." unless config

    dispatch_task(task_id, config)
  end

  def dispatch_task(task_id, config)
    return trigger_job_class(task_id, config) if config["class"]
    return trigger_queue_cleanup if task_id == "clear_solid_queue_finished_jobs"

    flash[:alert] = "Manual trigger not implemented for this command type."
  end

  # Safe because klass_name is retrieved from a fixed whitelist key lookup
  # (recurring_task_config), preventing Command Injection/RCE.
  def trigger_job_class(task_id, config)
    klass = config["class"].constantize
    args = config["args"] || []
    klass.perform_later(*args)
    flash[:notice] = "🚀 Triggered #{task_id} (#{config['class']})"
  end

  # Directly call the logic instead of spawning a subshell
  def trigger_queue_cleanup
    SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)
    flash[:notice] = "🚀 Executed queue cleanup directly."
  end
end
