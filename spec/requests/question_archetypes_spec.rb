# frozen_string_literal: true

require "rails_helper"

RSpec.describe "QuestionArchetypes" do
  it "renders the graph index with the most common archetypes" do
    archetype = create(:question_archetype, label: "why do you want to work here")
    create(:question_occurrence, question_archetype: archetype)

    get question_archetypes_path

    expect(response).to be_successful
    expect(response.body).to include("why do you want to work here").and include("Suggested handling")
  end

  it "renders an archetype with its occurrences, recommendation, and strategies" do
    archetype = create(:question_archetype)
    create(:question_occurrence, question_archetype: archetype, provider: "greenhouse")
    create(:answer_strategy, question_archetype: archetype, answer_text: "Mission fit.")

    get question_archetype_path(archetype)

    expect(response).to be_successful
    expect(response.body).to include("Mission fit.").and include("advisory")
  end

  it "merges one archetype into another on an explicit request" do
    source = create(:question_archetype, label: "src")
    target = create(:question_archetype, label: "dst")
    occurrence = create(:question_occurrence, question_archetype: source)

    post merge_question_archetype_path(source), params: { target_id: target.id }

    expect(response).to redirect_to(question_archetype_path(target))
    expect(occurrence.reload.question_archetype).to eq(target)
    expect(source.reload.merged_into).to eq(target)
  end

  it "splits checked occurrences into a new archetype" do
    archetype = create(:question_archetype)
    stay = create(:question_occurrence, question_archetype: archetype)
    move = create(:question_occurrence, question_archetype: archetype, raw_prompt: "Different?")

    post split_question_archetype_path(archetype), params: { occurrence_ids: [move.id], label: "new one" }

    new_archetype = QuestionArchetype.find_by(label: "new one")
    expect(move.reload.question_archetype).to eq(new_archetype)
    expect(stay.reload.question_archetype).to eq(archetype)
  end

  it "never fills or submits an answer -- the surface is read-only apart from merge/split" do
    expect { get question_archetypes_path }.not_to change(ApplicationFieldAnswer, :count)
  end

  it "records an appended readiness assessment when Mike sets one (TASK-127)" do
    archetype = create(:question_archetype)

    expect do
      post set_readiness_question_archetype_path(archetype),
           params: { readiness_class: "generatable", rationale: "usually close" }
    end.to change(ArchetypeReadinessAssessment, :count).by(1)

    expect(archetype.current_readiness).to have_attributes(readiness_class: "generatable", assessed_by: "mike")
  end
end
