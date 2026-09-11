# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::DocumentImporter, type: :service do
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "indeed", name: "Indeed") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:results) { [{ "external_id" => "1", "jobTitle" => "Engineer" }] }

  describe ".call" do
    it "imports new results and returns the imported count" do
      count = described_class.call("indeed", source, query, results)

      expect(count).to eq(1)
      doc = JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("indeed-1"))
      expect(doc).to be_present
      expect(doc.source_id).to eq(source.id)
      expect(doc.job_boards_query_id).to eq(query.id)
    end

    it "skips results whose signature already exists, without updating them" do
      described_class.call("indeed", source, query, results)
      original_document = JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("indeed-1")).document

      changed_results = [{ "external_id" => "1", "jobTitle" => "Changed Title" }]
      count = described_class.call("indeed", source, query, changed_results)

      expect(count).to eq(0)
      expect(JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("indeed-1")).document)
        .to eq(original_document)
    end
  end
end
