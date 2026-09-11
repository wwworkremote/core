# frozen_string_literal: true

class DatabaseBackupJob < ApplicationJob
  queue_as :default
  heavyweight!
  idempotent!

  CRITICAL_TABLES = %w[
    users career_profiles work_experiences experience_highlights
    contacts pipeline_steps company_pipeline_steps user_job_postings
    board_queries system_settings job_boards_sources
  ].freeze

  def perform
    backup_dir = Rails.root.join("data/backups")
    FileUtils.mkdir_p(backup_dir)

    run_backups(backup_dir)
  rescue StandardError => e
    Rails.logger.error "[DatabaseBackup] Critical error: #{e.message}"
  end

  private

  def run_backups(backup_dir)
    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    url = database_url
    full_backup = dump(backup_dir, "full_backup_#{timestamp}", url)
    critical_backup = dump(backup_dir, "critical_data_#{timestamp}", url, table_args: critical_table_args)

    File.exist?(critical_backup) ? finish_backup(backup_dir, full_backup, critical_backup) : log_missing_critical_backup
  end

  def database_url
    ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "primary").url
  end

  def critical_table_args
    CRITICAL_TABLES.flat_map { |t| ["-t", t] }
  end

  # Using array form of system to bypass shell and prevent injection
  def dump(backup_dir, filename, url, table_args: [])
    path = backup_dir.join("#{filename}.dump")
    system("pg_dump", "-Fc", "-d", url.to_s, *table_args, "-f", path.to_s)
    path
  end

  def finish_backup(backup_dir, full_backup, critical_backup)
    Rails.logger.info "[DatabaseBackup] Success. Full: #{full_backup}, Critical: #{critical_backup}"
    # Keep only last 7 days of backups
    prune_old_backups(backup_dir)
  end

  def log_missing_critical_backup
    Rails.logger.error "[DatabaseBackup] Failed to create critical dump file."
  end

  def prune_old_backups(dir)
    Dir.glob(File.join(dir, "*.dump")).each { |file| prune_if_old(file) }
  end

  def prune_if_old(file)
    return unless File.mtime(file) < 7.days.ago

    FileUtils.rm(file)
    Rails.logger.info "[DatabaseBackup] Pruned old backup: #{file}"
  end
end
