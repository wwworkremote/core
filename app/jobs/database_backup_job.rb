# frozen_string_literal: true

class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    backup_file = Rails.root.join('tmp', "wwworkremote_backup_#{timestamp}.dump")
    
    # Use custom-format dump for maximum flexibility
    # We assume pg_dump is available on the path
    begin
      db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "primary")
      url = db_config.url
      
      system("pg_dump -Fc -d #{url} -f #{backup_file}")
      
      if File.exist?(backup_file)
        Rails.logger.info "[DatabaseBackup] Created local dump: #{backup_file}"
        
        # TODO: Implement upload to offsite storage (S3/R2)
        # Offsite::BackupStore.upload(backup_file)
        
        # For now, keep in tmp and log
        # FileUtils.rm(backup_file)
      else
        Rails.logger.error "[DatabaseBackup] Failed to create dump file."
      end
    rescue StandardError => e
      Rails.logger.error "[DatabaseBackup] Critical error: #{e.message}"
    end
  end
end
