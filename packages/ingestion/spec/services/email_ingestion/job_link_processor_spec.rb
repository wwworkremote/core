# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::JobLinkProcessor do
  let(:record) { create(:email_import_record, source: "indeed", message_id: "msg-123") }
  let(:parsed_email) { { message_id: "msg-123", date: Time.current } }
  let(:job_link) { "https://indeed.com/job/1" }

  def stub_resolver(canonical_url)
    allow(EmailIngestion::CanonicalUrlResolver).to receive(:new)
      .and_return(instance_double(EmailIngestion::CanonicalUrlResolver, call: canonical_url))
  end

  def stub_fetch(result)
    allow(JobFetchers::PageFetch).to receive(:new).and_return(instance_double(JobFetchers::PageFetch, call: result))
  end

  def stub_extractor(job_data)
    allow(JobFetchers::CanonicalJobExtractor).to receive(:new)
      .and_return(instance_double(JobFetchers::CanonicalJobExtractor, call: job_data))
  end

  describe "#call" do
    it "creates a document with email provenance on the happy path" do
      stub_resolver("https://indeed.com/job/1/canonical")
      stub_fetch({ content: "<html></html>", final_url: "https://indeed.com/job/1/canonical",
                   fetch_mode: "static" })
      stub_extractor({ title: "Dev" })

      expect {
        described_class.new(job_link, parsed_email, record).call
      }.to change(JobBoards::Document, :count).by(1)

      payload = JSON.parse(JobBoards::Document.last.document)
      expect(payload["title"]).to eq("Dev")
      expect(payload["source_provider"]).to eq("indeed")
      expect(payload["discovered_url"]).to eq(job_link)
    end

    it "skips a link whose signature already exists" do
      stub_resolver("https://indeed.com/job/1/canonical")
      source = JobBoards::Source.find_or_create_by!(slug: "indeed") { |s| s.name = "Indeed" }
      query = JobBoards::Query.find_or_create_by!(source_id: source.id)
      signature = Digest::SHA256.hexdigest("msg-123-https://indeed.com/job/1/canonical")
      JobBoards::Document.create!(signature: signature, source_id: source.id, job_boards_query_id: query.id,
                                  document: "{}")

      expect {
        described_class.new(job_link, parsed_email, record).call
      }.not_to change(JobBoards::Document, :count)
    end

    it "does nothing when the page fetch fails" do
      stub_resolver("https://indeed.com/job/1/canonical")
      stub_fetch(nil)

      expect {
        described_class.new(job_link, parsed_email, record).call
      }.not_to change(JobBoards::Document, :count)
    end

    it "does nothing when extraction returns no data" do
      stub_resolver("https://indeed.com/job/1/canonical")
      stub_fetch({ content: "<html></html>", final_url: "https://indeed.com/job/1/canonical",
                   fetch_mode: "static" })
      stub_extractor(nil)

      expect {
        described_class.new(job_link, parsed_email, record).call
      }.not_to change(JobBoards::Document, :count)
    end

    it "logs and does not raise when the document fails to save" do
      stub_resolver("https://indeed.com/job/1/canonical")
      stub_fetch({ content: "<html></html>", final_url: "https://indeed.com/job/1/canonical",
                   fetch_mode: "static" })
      stub_extractor({}) # no title -- job_data present but effectively empty
      doc = JobBoards::Document.new
      allow(JobBoards::Document).to receive(:find_or_initialize_by).and_return(doc)
      allow(doc).to receive_messages(save: false, errors: instance_double(ActiveModel::Errors, full_messages: ["boom"]))
      allow(Rails.logger).to receive(:error)

      expect { described_class.new(job_link, parsed_email, record).call }.not_to raise_error
      expect(Rails.logger).to have_received(:error).with(/Failed to save document/)
    end
  end
end
