# frozen_string_literal: true

# TASK-127 AC#3: the sidepanel records what Mike did with a filled answer
# proposal here. The controller passes `proposed_text` / `final_text` to
# AnswerProposalVerdicts::Record, which hashes them and keeps only the numbers
# -- the text is never persisted or logged.
class Api::V0::AnswerProposalVerdictsController < ApiController
  def create
    verdict = AnswerProposalVerdicts::Record.from_fill(**verdict_params.to_h.symbolize_keys)
    return render(json: no_archetype, status: :unprocessable_content) unless verdict

    render json: { success: true, id: verdict.id }
  end

  private

  def no_archetype = { success: false, error: "no archetype for question" }

  def verdict_params
    params.expect(answer_proposal_verdict: %i[question_text strategy_source proposed_text final_text])
  end
end
