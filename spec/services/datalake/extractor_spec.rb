# frozen_string_literal: true

require "rails_helper"

# ADR 010 / TASK-123 read contract.
RSpec.describe Datalake::Extractor do
  let(:bundle) { instance_double(Datalake::Bundle) }

  it "makes a subclass declare a version" do
    klass = Class.new(described_class)
    expect { klass.version }.to raise_error(NotImplementedError, /must declare a version/)
  end

  it "runs #extract through .call and exposes the bundle + version" do
    klass = Class.new(described_class) do
      def self.version = "v3"
      def extract = { bundle: bundle, version: version }
    end

    expect(klass.call(bundle)).to eq(bundle: bundle, version: "v3")
  end

  it "flags a stale version stamp for re-extraction" do
    klass = Class.new(described_class) { def self.version = "v2" }

    expect(klass.stale?("v1")).to be(true)
    expect(klass.stale?("v2")).to be(false)
  end

  it "defaults #key to the demodulized underscored class name" do
    stub_const("Datalake::Extractors::DomQuestions", Class.new(described_class))
    expect(Datalake::Extractors::DomQuestions.key).to eq("dom_questions")
  end
end
