# frozen_string_literal: true

require "pdf-reader"
require "docx"

class LLM::DocumentProcessor
  DOCX_CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

  def self.extract_text(attachment)
    # attachment can be an ActiveStorage::Attachment or a Blob
    blob = attachment.respond_to?(:blob) ? attachment.blob : attachment
    return nil unless blob

    blob.open { |file| extract_by_content_type(blob.content_type, file.path) }
  rescue StandardError => e
    log_extraction_error(attachment, e)
  end

  def self.extract_by_content_type(content_type, path)
    case content_type
    when "application/pdf" then extract_pdf_text(path)
    when DOCX_CONTENT_TYPE then extract_docx_text(path)
    else File.read(path) # Fallback for plain text or unknown
    end
  end

  def self.log_extraction_error(attachment, error)
    Rails.logger.error "[DocumentProcessor] Failed to extract text from #{attachment.filename}: #{error.message}"
    nil
  end

  def self.extract_pdf_text(path)
    reader = PDF::Reader.new(path)
    reader.pages.map(&:text).join("\n")
  end

  def self.extract_pdf_text_for_all(career_profile)
    career_profile.resumes.filter_map { |resume| resume_text_entry(resume) }
  end

  def self.resume_text_entry(resume)
    { filename: resume.filename.to_s, content: extract_text(resume) }
  end

  def self.extract_docx_text(path)
    doc = Docx::Document.open(path)
    doc.paragraphs.join("\n")
  end
end
