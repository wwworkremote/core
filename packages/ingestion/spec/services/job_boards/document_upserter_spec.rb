# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::DocumentUpserter, type: :service do
  let(:source) { JobBoards::Source.find_or_create_by!(slug: "lever", name: "Lever") }
  let(:query) { JobBoards::Query.find_or_create_by!(source_id: source.id) }
  let(:job_data) { { "id" => "42", "text" => "Remote Ruby Engineer" } }
  let(:context) do
    described_class::Context.new(
      provider: "lever", slug: "gitlab", slug_key: "site_slug", term: term,
      match_field: "text", source_id: source.id, query_id: query.id
    )
  end

  describe ".call" do
    context "when the term is blank" do
      let(:term) { "" }

      it "creates a document tagged with the provider signature and slug key" do
        expect { described_class.call(context, job_data) }.to change(JobBoards::Document, :count).by(1)

        doc = JobBoards::Document.find_by(signature: "lever-gitlab-42")
        payload = JSON.parse(doc.document)
        expect(payload["site_slug"]).to eq("gitlab")
        expect(payload["found_by_terms"]).to eq([])
      end
    end

    context "when the term matches the match_field" do
      let(:term) { "ruby" }

      it "creates the document and records the matched term" do
        described_class.call(context, job_data)

        payload = JSON.parse(JobBoards::Document.find_by(signature: "lever-gitlab-42").document)
        expect(payload["found_by_terms"]).to eq(["ruby"])
      end
    end

    context "when the term does not match the match_field" do
      let(:term) { "python" }

      it "does not create a document" do
        expect { described_class.call(context, job_data) }.not_to change(JobBoards::Document, :count)
      end
    end

    context "when the document already exists" do
      let(:term) { "ruby" }

      it "merges found_by_terms instead of overwriting the payload, without duplicating a term" do
        described_class.call(context, job_data)
        described_class.call(context, job_data)

        expect(JobBoards::Document.count).to eq(1)
        payload = JSON.parse(JobBoards::Document.last.document)
        expect(payload["found_by_terms"]).to eq(["ruby"])
      end
    end
  end
end
