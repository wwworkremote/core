# frozen_string_literal: true

require 'pdf-reader'
require 'docx'

module LLM
  class DocumentProcessor
    def self.extract_text(attachment)
      # attachment can be an ActiveStorage::Attachment or a Blob
      blob = attachment.respond_to?(:blob) ? attachment.blob : attachment
      return nil unless blob

      blob.open do |file|
        case blob.content_type
        when 'application/pdf'
          extract_pdf_text(file.path)
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          extract_docx_text(file.path)
        else
          # Fallback for plain text or unknown
          File.read(file.path)
        end
      end
    rescue StandardError => e
      Rails.logger.error "[DocumentProcessor] Failed to extract text from #{attachment.filename}: #{e.message}"
      nil
    end

    def self.extract_pdf_text(path)
      reader = PDF::Reader.new(path)
      reader.pages.map(&:text).join("\n")
    end

    def self.extract_pdf_text_for_all(career_profile)
      career_profile.resumes.map do |resume|
        {
          filename: resume.filename.to_s,
          content: extract_text(resume)
        }
      end.compact
    end

    def self.extract_docx_text(path)
      doc = Docx::Document.open(path)
      doc.paragraphs.map(&:to_s).join("\n")
    end
  end
end
