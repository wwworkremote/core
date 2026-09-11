# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::DocumentProcessor do
  let(:career_profile) { create(:career_profile) }

  describe ".extract_text" do
    it "handles plain text files" do
      blob = double(content_type: "text/plain", filename: "test.txt")
      allow(blob).to receive(:open).and_yield(double(path: Rails.root.join("Gemfile").to_s))

      res = described_class.extract_text(blob)
      expect(res).to include('source "https://rubygems.org"')
    end

    it "delegates to extract_pdf_text for PDFs" do
      blob = double(content_type: "application/pdf", filename: "test.pdf")
      allow(blob).to receive(:open).and_yield(double(path: "/tmp/test.pdf"))
      allow(described_class).to receive(:extract_pdf_text).with("/tmp/test.pdf").and_return("PDF Content")

      expect(described_class.extract_text(blob)).to eq("PDF Content")
      expect(described_class).to have_received(:extract_pdf_text).with("/tmp/test.pdf")
    end

    it "delegates to extract_docx_text for docx files" do
      docx_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      blob = double(content_type: docx_type, filename: "test.docx")
      allow(blob).to receive(:open).and_yield(double(path: "/tmp/test.docx"))
      allow(described_class).to receive(:extract_docx_text).with("/tmp/test.docx").and_return("Docx Content")

      expect(described_class.extract_text(blob)).to eq("Docx Content")
      expect(described_class).to have_received(:extract_docx_text).with("/tmp/test.docx")
    end

    it "handles extraction errors gracefully" do
      blob = double(content_type: "application/pdf", filename: "test.pdf")
      allow(blob).to receive(:open).and_raise(StandardError.new("Corrupt"))
      allow(Rails.logger).to receive(:error)

      expect(described_class.extract_text(blob)).to be_nil
      expect(Rails.logger).to have_received(:error).with(/Failed to extract text from test.pdf: Corrupt/)
    end
  end

  describe ".extract_pdf_text_for_all" do
    it "extracts text for each resume attached to the career profile" do
      resume = double(filename: "resume.pdf")
      allow(career_profile).to receive(:resumes).and_return([resume])
      allow(described_class).to receive(:extract_text).with(resume).and_return("Resume text")

      result = described_class.extract_pdf_text_for_all(career_profile)

      expect(result).to eq([{ filename: "resume.pdf", content: "Resume text" }])
    end
  end

  describe ".extract_pdf_text" do
    it "uses PDF::Reader to extract text" do
      mock_reader = instance_double(PDF::Reader, pages: [double(text: "Page 1"), double(text: "Page 2")])
      allow(PDF::Reader).to receive(:new).and_return(mock_reader)

      expect(described_class.extract_pdf_text("path.pdf")).to eq("Page 1\nPage 2")
    end
  end

  describe ".extract_docx_text" do
    it "uses Docx::Document to extract text" do
      mock_doc = instance_double(Docx::Document, paragraphs: ["Para 1", "Para 2"])
      allow(Docx::Document).to receive(:open).and_return(mock_doc)

      expect(described_class.extract_docx_text("path.docx")).to eq("Para 1\nPara 2")
    end
  end
end
