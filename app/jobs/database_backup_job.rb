# frozen_string_literal: true

class DatabaseBackupJob < ApplicationJob
  queue_as :default
  heavyweight!
  idempotent!

  def perform
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    backup_dir = Rails.root.join('data/backups')
    FileUtils.mkdir_p(backup_dir)

    full_backup = backup_dir.join("full_backup_#{timestamp}.dump")
    critical_backup = backup_dir.join("critical_data_#{timestamp}.dump")

    begin
      db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: 'primary')
      url = db_config.url

      # 1. Full Backup (Logical)
      # Using array form of system to bypass shell and prevent injection
      system('pg_dump', '-Fc', '-d', url.to_s, '-f', full_backup.to_s)

      # 2. Selective Critical Backup
      critical_tables = %w[
        users career_profiles work_experiences experience_highlights
        contacts pipeline_steps company_pipeline_steps user_job_postings
        board_queries system_settings job_boards_sources
      ]

      table_args = critical_tables.flat_map { |t| ['-t', t] }
      system('pg_dump', '-Fc', '-d', url.to_s, *table_args, '-f', critical_backup.to_s)

      if File.exist?(critical_backup)
        Rails.logger.info "[DatabaseBackup] Success. Full: #{full_backup}, Critical: #{critical_backup}"
        # Keep only last 7 days of backups
        prune_old_backups(backup_dir)
      else
        Rails.logger.error '[DatabaseBackup] Failed to create critical dump file.'
      end
    rescue StandardError => e
      Rails.logger.error "[DatabaseBackup] Critical error: #{e.message}"
    end
  end

  private

  def prune_old_backups(dir)
    Dir.glob(File.join(dir, '*.dump')).each do |file|
      if File.mtime(file) < 7.days.ago
        FileUtils.rm(file)
        Rails.logger.info "[DatabaseBackup] Pruned old backup: #{file}"
      end
    end
  end
end
