# frozen_string_literal: true

module LLM
  class JobSchedulerInspector
    CONFIG_PATH = Rails.root.join('config/recurring.yml')
    
    UTILITY_JOBS = %w[nightly_database_backup clear_solid_queue_finished_jobs].freeze

    def self.call
      new.call
    end

    def call
      return [] unless File.exist?(CONFIG_PATH)

      config = YAML.load_file(CONFIG_PATH)[Rails.env] || {}
      
      all_tasks = config.map do |key, task_config|
        build_task_info(key, task_config)
      end

      # Group by Utility first, then others
      {
        utilities: all_tasks.select { |t| UTILITY_JOBS.include?(t[:id]) },
        pipeline: all_tasks.reject { |t| UTILITY_JOBS.include?(t[:id]) }
      }
    end

    private

    def build_task_info(id, config)
      class_name = config['class'] || 'Command'
      
      # Try to find last execution in SolidQueue
      # Note: Solid Queue stores recurring execution info in solid_queue_recurring_executions
      last_execution = SolidQueue::RecurringExecution.where(task_key: id).order(created_at: :desc).first

      {
        id: id,
        class_name: class_name,
        schedule: config['schedule'],
        last_run: last_execution&.created_at,
        status: last_execution&.job&.finished_at ? 'finished' : (last_execution ? 'running/failed' : 'never'),
        command: config['command'],
        args: config['args']
      }
    end
  end
end
