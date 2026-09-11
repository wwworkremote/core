# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::Scanner do
  let(:base_dir) { Dir.mktmpdir }
  let(:source) { "indeed" }
  let(:source_dir) { File.join(base_dir, source) }
  let(:eml_path) { File.join(source_dir, "test.eml") }

  before do
    stub_const("EmailIngestion::Scanner::BASE_DIR", base_dir)
    FileUtils.mkdir_p(source_dir)
    File.write(eml_path, "Subject: Job Alert\n\nTest content")
  end

  after do
    FileUtils.rm_rf(base_dir)
  end

  describe "#call" do
    it "discovers eml files and creates import records" do
      expect {
        described_class.new.call
      }.to change(EmailImportRecord, :count).by(1)

      record = EmailImportRecord.last
      expect(record.source).to eq("indeed")
      expect(record.status).to eq("pending")
    end

    it "skips already processed files via checksum" do
      described_class.new.call
      expect(EmailImportRecord.count).to eq(1)

      # Second scan of the same file
      described_class.new.call
      expect(EmailImportRecord.count).to eq(1)
    end

    it "handles missing directories gracefully" do
      FileUtils.rm_rf(source_dir)
      expect {
        described_class.new.call
      }.not_to raise_error
    end
  end
end
