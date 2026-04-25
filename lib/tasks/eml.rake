# frozen_string_literal: true

namespace :eml do
  desc "Scan local directories for .eml files and process them"
  task scan: :environment do
    EmailScanner.new.call
  end

  desc "Scan a specific source directory for .eml files"
  task :scan_source, [:source] => :environment do |_, args|
    source = args[:source]
    if source.blank?
      puts "Usage: rake eml:scan_source[indeed]"
      exit
    end

    base_dir = File.expand_path("~/.wwworkremote")
    source_dir = File.join(base_dir, source)

    unless Dir.exist?(source_dir)
      puts "Directory not found: #{source_dir}"
      exit
    end

    Dir.glob(File.join(source_dir, "*.eml")).each do |file_path|
      checksum = Digest::SHA256.file(file_path).hexdigest
      record = EmailFileClaim.new(file_path, source, checksum).call
      if record
        puts "Processing #{file_path}..."
        EmailImporter.new(record).call
      else
        puts "Skipping #{file_path} (already processed or currently processing)"
      end
    end
  end

  desc "Process a single .eml file"
  task :process_file, %i[file_path source] => :environment do |_, args|
    file_path = args[:file_path]
    source = args[:source]

    if file_path.blank? || source.blank?
      puts "Usage: rake eml:process_file[path/to/file.eml,indeed]"
      exit
    end

    full_path = File.expand_path(file_path)
    unless File.exist?(full_path)
      puts "File not found: #{full_path}"
      exit
    end

    checksum = Digest::SHA256.file(full_path).hexdigest
    record = EmailFileClaim.new(full_path, source, checksum).call
    if record
      puts "Processing #{full_path}..."
      EmailImporter.new(record).call
    else
      puts "Skipping #{full_path} (already processed or currently processing)"
    end
  end
end
