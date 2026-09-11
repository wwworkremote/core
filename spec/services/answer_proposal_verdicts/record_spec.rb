# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnswerProposalVerdicts::Record do
  let(:posting) { create(:job_posting) }
  let(:user) { create(:user) }
  let(:question) { posting.application_questions.create!(user: user, question_text: "Why do you want to work here?") }

  before do
    create(:question_archetype, canonical_prompt: "why do you want to work here", question_kind: "motivation")
  end

  describe ".for_generated" do
    it "writes one declined, value-free verdict for the proposal shown" do
      expect { described_class.for_generated(question, "Because the mission.", "ai") }
        .to change(AnswerProposalVerdict, :count).by(1)

      verdict = AnswerProposalVerdict.last
      expect(verdict).to have_attributes(strategy_source: "ai", verdict: "declined", final_text_sha256: nil)
      expect(verdict.proposed_text_sha256).to eq(Digest::SHA256.hexdigest("Because the mission."))
    end
  end

  describe ".resolve" do
    it "flips the open verdict to edited with a real edit distance" do
      described_class.for_generated(question, "Because the mission.", "ai")

      described_class.resolve(question, proposed_text: "Because the mission.",
                                        final_text: "Because the mission resonates.")

      verdict = AnswerProposalVerdict.last
      expect(verdict.verdict).to eq("edited")
      expect(verdict.edit_distance).to be > 0
    end

    it "flips to accepted when the answer went out verbatim" do
      described_class.for_generated(question, "Because the mission.", "ai")
      described_class.resolve(question, proposed_text: "Because the mission.", final_text: "Because the mission.")

      expect(AnswerProposalVerdict.last).to have_attributes(verdict: "accepted", edit_distance: 0)
    end
  end
end
