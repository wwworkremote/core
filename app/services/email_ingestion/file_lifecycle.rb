# frozen_string_literal: true

require 'fileutils'

module EmailIngestion
  class FileLifecycle
    def initialize(file_path, source)
      @file_path = file_path
      @source = source
    end

    def processed
      move_to('processed')
    end

    def error
      move_to('error')
    end

    private

    def move_to(subdir)
      return unless File.exist?(@file_path)

      base_dir = File.dirname(@file_path, 2)
      target_dir = File.join(base_dir, subdir, @source)
      FileUtils.mkdir_p(target_dir)

      filename = File.basename(@file_path)
      target_path = File.join(target_dir, filename)

      # Handle potential collisions in processed/error directories
      if File.exist?(target_path)
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')
        target_path = File.join(target_dir, "#{timestamp}_#{filename}")
      end

      FileUtils.move(@file_path, target_path)
    end
  end
end
