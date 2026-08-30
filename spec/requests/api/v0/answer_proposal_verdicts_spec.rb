# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::AnswerProposalVerdicts" do
  before { create(:question_archetype, canonical_prompt: "why do you want to work here", question_kind: "motivation") }

  it "records a value-free verdict from a template fill without persisting the text" do
    expect do
      post "/api/v0/answer_proposal_verdicts", params: { answer_proposal_verdict: {
        question_text: "Why do you want to work here?", strategy_source: "template",
        proposed_text: "Because the mission.", final_text: "Because the mission, honestly."
      } }
    end.to change(AnswerProposalVerdict, :count).by(1)

    verdict = AnswerProposalVerdict.last
    expect(verdict).to have_attributes(strategy_source: "template", verdict: "edited")
    expect(verdict.edit_distance).to be > 0
    expect(AnswerProposalVerdict.column_names).not_to include("proposed_text", "final_text")
  end

  it "422s when the question has no archetype" do
    post "/api/v0/answer_proposal_verdicts", params: { answer_proposal_verdict: {
      question_text: "Some brand new question nobody has asked", strategy_source: "template",
      proposed_text: "a", final_text: "a"
    } }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
