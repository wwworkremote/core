# frozen_string_literal: true

module ResumeManager
  # Deep module for managing the complete lifecycle of a Resume.
  # Provides a single interface for forking, diffing, and projecting (exporting) resumes.

  def self.fork(resume, new_name: nil)
    ForkService.new(resume).call(new_name: new_name)
  end

  def self.diff(resume_a, resume_b)
    DiffService.new(resume_a, resume_b).call
  end

  def self.export(resume, format:)
    exporter = ResumeExportService.new(resume)
    case format.to_sym
    when :json then exporter.to_json
    when :markdown then exporter.to_markdown
    when :text then exporter.to_text
    when :mcp then exporter.to_mcp
    when :pdf then exporter.to_pdf
    else raise ArgumentError, "Unsupported export format: #{format}"
    end
  end

  def self.import(user, url:, name: "Imported Resume")
    ResumeImportService.new(user).from_url(url, name: name)
  end
end
