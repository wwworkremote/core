# frozen_string_literal: true

class LLM::JobSchedulerInspector
  CONFIG_PATH = Rails.root.join("config/recurring.yml")

  UTILITY_JOBS = %w[nightly_database_backup clear_solid_queue_finished_jobs].freeze

  def self.call
    new.call
  end

  def call
    return [] unless File.exist?(CONFIG_PATH)

    group_tasks(build_tasks(env_config))
  end

  private

  def env_config
    all_configs = YAML.load_file(CONFIG_PATH)
    all_configs[Rails.env] || all_configs["development"] || {}
  end

  def build_tasks(config)
    config.map { |key, task_config| build_task_info(key, task_config) }
  end

  # Group by Utility first, then others
  def group_tasks(tasks)
    {
      utilities: tasks.select { |t| UTILITY_JOBS.include?(t[:id]) },
      pipeline: tasks.reject { |t| UTILITY_JOBS.include?(t[:id]) }
    }
  end

  def build_task_info(id, config)
    last_execution = last_execution_for(id)
    { id: id, class_name: config["class"] || "Command", schedule: config["schedule"],
      last_run: last_execution&.created_at, status: execution_status(last_execution),
      command: config["command"], args: config["args"] }
  end

  # Solid Queue stores recurring execution info in
  # solid_queue_recurring_executions.
  def last_execution_for(id)
    SolidQueue::RecurringExecution.where(task_key: id).order(created_at: :desc).first
  end

  def execution_status(last_execution)
    return "never" unless last_execution
    return "finished" if last_execution.job&.finished_at

    "running/failed"
  end
end
