# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeManager do
  describe ".export" do
    let(:resume) { create(:resume) }

    it "dispatches to the exporter's method for each supported format" do
      expect(described_class.export(resume, format: :json)).to eq(ResumeExportService.new(resume).to_json)
      expect(described_class.export(resume, format: :markdown)).to be_a(String)
      expect(described_class.export(resume, format: :text)).to be_a(String)
    end

    it "raises for an unsupported format" do
      expect {
        described_class.export(resume, format: :xml)
      }.to raise_error(ArgumentError, "Unsupported export format: xml")
    end
  end
end
