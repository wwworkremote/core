# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationFieldQuestionClassifier do
  it "classifies labels and normalizes them for cross-application comparison" do
    expect(described_class.call("Are you legally authorized to work?")).to eq(question_kind: "eligibility",
                                                                              normalized_prompt: "are you legally authorized to work")
  end

  it "uses free_text for an otherwise unknown textarea" do
    expect(described_class.call("Tell us something unusual", type: "textarea")[:question_kind]).to eq("free_text")
  end
end
