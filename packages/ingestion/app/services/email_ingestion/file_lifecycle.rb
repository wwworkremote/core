# frozen_string_literal: true

require "fileutils"

class EmailIngestion::FileLifecycle
  def initialize(file_path, source)
    @file_path = file_path
    @source = source
  end

  def processed
    move_to("processed")
  end

  def error
    move_to("error")
  end

  private

  # rubocop:disable Metrics/MethodLength
  def move_to(subdir)
    return unless File.exist?(@file_path)

    target_dir = target_directory(subdir)
    FileUtils.mkdir_p(target_dir)
    target_path = collision_safe_path(target_dir)

    FileUtils.move(@file_path, target_path)
    target_path
  end
  # rubocop:enable Metrics/MethodLength

  def target_directory(subdir)
    base_dir = File.dirname(@file_path, 2)
    File.join(base_dir, subdir, @source)
  end

  # Handle potential collisions in processed/error directories
  def collision_safe_path(target_dir)
    filename = File.basename(@file_path)
    target_path = File.join(target_dir, filename)
    return target_path unless File.exist?(target_path)

    timestamp = Time.current.strftime("%Y%m%d%H%M%S")
    File.join(target_dir, "#{timestamp}_#{filename}")
  end
end
