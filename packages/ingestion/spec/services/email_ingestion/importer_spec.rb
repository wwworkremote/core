# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::Importer do
  let(:record) { create(:email_import_record, source: "indeed", file_path: "/tmp/test.eml") }
  let(:importer) { described_class.new(record) }

  before do
    # Stub internal components to focus on Importer orchestration
    allow(EmailIngestion::MessageParser).to receive(:new).and_return(
      instance_double(EmailIngestion::MessageParser, call: { message_id: "msg-123", date: Time.current })
    )
    allow(EmailIngestion::LinkExtractor).to receive(:new).and_return(
      instance_double(EmailIngestion::LinkExtractor, call: ["https://indeed.com/job/1"])
    )
    allow(EmailIngestion::CanonicalUrlResolver).to receive(:new).and_return(
      instance_double(EmailIngestion::CanonicalUrlResolver, call: "https://indeed.com/job/1/canonical")
    )
    allow(JobFetchers::PageFetch).to receive(:new).and_return(
      instance_double(JobFetchers::PageFetch, call: { content: "<html></html>", final_url: "https://indeed.com/job/1/canonical" })
    )
    allow(JobFetchers::CanonicalJobExtractor).to receive(:new).and_return(
      instance_double(JobFetchers::CanonicalJobExtractor, call: { title: "Dev" })
    )
    allow(EmailIngestion::FileLifecycle).to receive(:new).and_return(
      instance_double(EmailIngestion::FileLifecycle, processed: true, error: true)
    )
    allow_any_instance_of(JobBoards::Syncer).to receive(:call)
  end

  describe "#call" do
    it "processes the record and creates a document" do
      expect {
        importer.call
      }.to change(JobBoards::Document, :count).by(1)

      record.reload
      expect(record.status).to eq("processed")
      expect(record.message_id).to eq("msg-123")
    end

    it "handles errors and updates record status" do
      allow(EmailIngestion::MessageParser).to receive(:new).and_raise(StandardError.new("Parse failed"))
      
      importer.call
      record.reload
      expect(record.status).to eq("error")
      expect(record.error_message).to eq("Parse failed")
    end

    it "skips processing if no links found" do
      allow(EmailIngestion::LinkExtractor).to receive(:new).and_return(
        instance_double(EmailIngestion::LinkExtractor, call: [])
      )

      expect {
        importer.call
      }.not_to change(JobBoards::Document, :count)

      expect(record.reload.status).to eq("processed")
    end
  end
end
