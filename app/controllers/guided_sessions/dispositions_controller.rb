# frozen_string_literal: true

# Mike's disposition of a Reference Comparison finding on a guided session's
# review page (ADR 009). Split out of GuidedSessionsController so session
# lifecycle and comparison review stay separate concerns.
class GuidedSessions::DispositionsController < ApplicationController
  REVIEWER = ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")

  def create
    finding.finding_dispositions.create!(disposition_attrs)
    redirect_to guided_session_path(guided_session), notice: "Disposition recorded."
  end

  private

  def guided_session
    @guided_session ||= GuidedSession.find(params.expect(:id))
  end

  def finding
    @finding ||= ComparisonFinding
                 .where(reference_comparison_id: guided_session.reference_comparisons.select(:id))
                 .find(params.expect(:finding_id))
  end

  def disposition_attrs
    value = params.expect(:value)
    { value: value, rationale: params[:rationale].presence, reviewer: REVIEWER, reviewer_label: "Mike",
      source_disposition_id: carried_forward_id(value) }
  end

  def carried_forward_id(value)
    finding.suggested_disposition_id if finding.suggested_disposition&.value == value
  end
end
