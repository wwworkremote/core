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

  EXPORT_METHODS = {
    json: :to_json,
    markdown: :to_markdown,
    text: :to_text,
    mcp: :to_mcp,
    pdf: :to_pdf
  }.freeze

  def self.export(resume, format:)
    method_name = EXPORT_METHODS.fetch(format.to_sym) { raise ArgumentError, "Unsupported export format: #{format}" }
    ResumeExportService.new(resume).public_send(method_name)
  end

  def self.import(user, url:, name: "Imported Resume")
    ResumeImportService.new(user).from_url(url, name: name)
  end
end
