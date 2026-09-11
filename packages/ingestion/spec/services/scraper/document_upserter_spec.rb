# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scraper::DocumentUpserter, type: :service do
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "dice", name: "Dice") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:results) { [{ "external_id" => "1", "jobTitle" => "Engineer" }] }

  describe ".call" do
    it "persists new results and returns the processed count" do
      count = described_class.call("dice", source, query, results)

      expect(count).to eq(1)
      doc = JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("dice-1"))
      expect(doc).to be_present
      expect(doc.source_id).to eq(source.id)
      expect(doc.job_boards_query_id).to eq(query.id)
      expect(doc.aasm_state).to eq("pending")
    end

    it "overwrites an existing signature match on every sighting" do
      described_class.call("dice", source, query, results)

      changed_results = [{ "external_id" => "1", "jobTitle" => "Changed Title" }]
      count = described_class.call("dice", source, query, changed_results)

      expect(count).to eq(1)
      doc = JobBoards::Document.find_by(signature: Digest::SHA256.hexdigest("dice-1"))
      expect(JSON.parse(doc.document)["jobTitle"]).to eq("Changed Title")
    end
  end
end
