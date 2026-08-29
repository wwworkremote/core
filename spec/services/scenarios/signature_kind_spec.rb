# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::SignatureKind do
  describe ".for" do
    it "classifies a bare kind as an ATS identity and round-trips it unchanged" do
      parsed = described_class.for("job_post_id")

      expect(parsed).to have_attributes(
        classification: :ats_identity, namespace: nil, identifier: "job_post_id", raw: "job_post_id"
      )
      expect(parsed.ats_identity?).to be(true)
    end

    it "parses each structural namespace into namespace + identifier" do
      expect(described_class.for("field:work_authorization")).to have_attributes(
        classification: :structural, namespace: "field", identifier: "work_authorization"
      )
      expect(described_class.for("step:resolution.2")).to have_attributes(
        namespace: "step", identifier: "resolution.2"
      )
      expect(described_class.for("commitment_boundary:submit")).to have_attributes(
        namespace: "commitment_boundary", identifier: "submit"
      )
    end

    it "splits the screening_question identifier into version and hash" do
      parsed = described_class.for("screening_question:v1:abc123")

      expect(parsed).to have_attributes(
        classification: :structural,
        namespace: "screening_question",
        identifier: "v1:abc123",
        screening_question_version: "v1",
        screening_question_hash: "abc123"
      )
    end

    it "returns nil version/hash accessors for non-screening kinds" do
      parsed = described_class.for("field:work_authorization")

      expect(parsed.screening_question_version).to be_nil
      expect(parsed.screening_question_hash).to be_nil
    end

    it "raises on an unknown namespace in the test environment" do
      expect { described_class.for("feild:typo") }
        .to raise_error(described_class::UnknownNamespaceError, "feild:typo")
    end

    it "logs a diagnostic before raising on an unknown namespace" do
      allow(Rails.logger).to receive(:warn)

      expect { described_class.for("mystery:thing") }.to raise_error(described_class::UnknownNamespaceError)
      expect(Rails.logger).to have_received(:warn).with(/unknown namespace "mystery" in "mystery:thing"/)
    end

    context "outside dev/test (production degrade path)" do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production")) }

      it "returns an unknown_namespace Parsed with a diagnostic instead of raising" do
        allow(Rails.logger).to receive(:warn)

        parsed = described_class.for("mystery:thing")

        expect(parsed.classification).to eq(:unknown_namespace)
        expect(parsed.unknown_namespace?).to be(true)
        expect(Rails.logger).to have_received(:warn).with(/unknown namespace "mystery"/)
      end
    end
  end

  describe ".build" do
    it "builds a namespaced kind for a whitelisted namespace" do
      expect(described_class.build(:field, "work_authorization")).to eq("field:work_authorization")
      expect(described_class.build("step", "intake.1")).to eq("step:intake.1")
    end

    it "rejects a namespace outside the whitelist" do
      expect { described_class.build("bogus", "x") }
        .to raise_error(ArgumentError, /unknown structural namespace: "bogus"/)
    end

    it "round-trips through .for" do
      kind = described_class.build(:commitment_boundary, "submit")

      expect(described_class.for(kind)).to have_attributes(namespace: "commitment_boundary", identifier: "submit")
    end
  end

  describe ".screening_question" do
    it "produces a versioned sha256 kind" do
      kind = described_class.screening_question("Are you authorized to work in the US?")

      expect(kind).to match(/\Ascreening_question:v1:[0-9a-f]{64}\z/)
    end

    it "normalizes case and whitespace so equivalent wording hashes the same" do
      a = described_class.screening_question("Are you authorized to work in the US?")
      b = described_class.screening_question("  are you   authorized to work in the us? ")

      expect(a).to eq(b)
    end

    it "hashes materially different wording differently" do
      a = described_class.screening_question("Are you authorized to work in the US?")
      b = described_class.screening_question("Do you now or in the future require sponsorship?")

      expect(a).not_to eq(b)
    end

    it "is readable back through .for" do
      parsed = described_class.for(described_class.screening_question("Any felony convictions?"))

      expect(parsed.screening_question_version).to eq("v1")
      expect(parsed.screening_question_hash).to match(/\A[0-9a-f]{64}\z/)
    end
  end
end
