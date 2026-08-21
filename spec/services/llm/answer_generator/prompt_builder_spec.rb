# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::AnswerGenerator::PromptBuilder do
  let(:profile) { create(:career_profile, skills: "Ruby", goals: "Staff+ platform work") }
  let(:job_posting) { create(:job_posting, title: "Principal Engineer", company: "Acme") }

  def build_experience(title:, summary:, start_date: 1.year.ago)
    create(:work_experience, career_profile: profile, title: title, company_name: "Somewhere",
                             summary: summary, impact: "Shipped it", start_date: start_date)
  end

  describe "experience selection" do
    # The failure this guards against: with a long history, every experience
    # was sent on every question, so the one entry that actually answered it
    # was buried and the model -- told to use only the facts below -- answered
    # from whatever was nearest instead.
    it "puts the topically relevant experience ahead of more recent irrelevant ones" do
      build_experience(title: "Warehouse Manager", summary: "Inventory logistics", start_date: 1.month.ago)
      build_experience(title: "Barista", summary: "Coffee service", start_date: 2.months.ago)
      build_experience(title: "Platform Engineer", summary: "Built agentic MCP server tooling",
                       start_date: 10.years.ago)

      prompt = described_class.call(profile, job_posting, "Describe agentic MCP tooling you built")

      expect(prompt).to match(/Platform Engineer.*Warehouse Manager/m)
    end

    it "caps how many experiences reach the prompt" do
      (described_class::MAX_EXPERIENCES + 4).times { |i| build_experience(title: "Role #{i}", summary: "Work #{i}") }

      prompt = described_class.call(profile, job_posting, "Tell me about your background")

      expect(prompt.scan(/^- Role \d+\./).size).to eq(described_class::MAX_EXPERIENCES)
    end

    # No separate no-match branch exists, so this is what keeps the fallback
    # honest: every score ties at 0 and recency alone decides.
    it "falls back to most-recent order when nothing matches the question" do
      build_experience(title: "Older Role", summary: "Something", start_date: 5.years.ago)
      build_experience(title: "Newer Role", summary: "Something", start_date: 1.month.ago)

      prompt = described_class.call(profile, job_posting, "zzzz qqqq")

      expect(prompt).to match(/Newer Role.*Older Role/m)
    end

    it "ignores short filler words when scoring relevance" do
      build_experience(title: "Filler Match", summary: "the and you for with that this", start_date: 9.years.ago)
      build_experience(title: "Real Match", summary: "kubernetes orchestration", start_date: 8.years.ago)

      prompt = described_class.call(profile, job_posting, "the and you for with that this kubernetes")

      expect(prompt).to match(/Real Match.*Filler Match/m)
    end
  end

  describe "semantic ranking" do
    # 768-dim one-hot vectors: cosine distance 0 to itself, 1 to the other.
    def unit_vector(index)
      Array.new(768, 0.0).tap { |v| v[index] = 1.0 }
    end

    before { allow(VectorIntelligence).to receive(:embed).and_return(unit_vector(0)) }

    it "prefers the nearest embedded experience over lexical overlap" do
      # Deliberately gives the WRONG answer all the lexical advantages: it
      # matches the question's words and is more recent. Only the embedding
      # says otherwise, so this fails if the semantic path isn't being used.
      build_experience(title: "Lexical Decoy", summary: "kubernetes orchestration platform",
                       start_date: 1.month.ago).update!(embedding: unit_vector(5))
      build_experience(title: "Semantic Winner", summary: "unrelated wording entirely",
                       start_date: 10.years.ago).update!(embedding: unit_vector(0))

      prompt = described_class.call(profile, job_posting, "kubernetes orchestration platform")

      expect(prompt).to match(/Semantic Winner.*Lexical Decoy/m)
    end

    it "ignores experiences that have not been embedded yet" do
      build_experience(title: "Embedded Role", summary: "Something").update!(embedding: unit_vector(0))
      build_experience(title: "Unembedded Role", summary: "Something")

      prompt = described_class.call(profile, job_posting, "anything")

      expect(prompt).to include("Embedded Role")
      expect(prompt).not_to include("Unembedded Role")
    end

    it "falls back to lexical ranking when the embedding service fails" do
      allow(VectorIntelligence).to receive(:embed).and_raise(Faraday::ConnectionFailed.new("down"))
      build_experience(title: "Filler Role", summary: "unrelated", start_date: 9.years.ago)
        .update!(embedding: unit_vector(0))
      build_experience(title: "Keyword Role", summary: "kubernetes orchestration", start_date: 8.years.ago)
        .update!(embedding: unit_vector(5))

      prompt = described_class.call(profile, job_posting, "kubernetes orchestration")

      expect(prompt).to match(/Keyword Role.*Filler Role/m)
    end

    it "falls back to lexical ranking when the question cannot be embedded" do
      allow(VectorIntelligence).to receive(:embed).and_return(nil)
      build_experience(title: "Older Role", summary: "Something", start_date: 5.years.ago)
        .update!(embedding: unit_vector(0))
      build_experience(title: "Newer Role", summary: "Something", start_date: 1.month.ago)
        .update!(embedding: unit_vector(1))

      prompt = described_class.call(profile, job_posting, "zzzz")

      expect(prompt).to match(/Newer Role.*Older Role/m)
    end
  end

  describe "prompt contents" do
    it "includes the question, profile and job posting" do
      build_experience(title: "Engineer", summary: "Built things")

      prompt = described_class.call(profile, job_posting, "Why this role?")

      expect(prompt).to include("Why this role?", "Ruby", "Staff+ platform work", "Principal Engineer", "Acme")
    end
  end
end
