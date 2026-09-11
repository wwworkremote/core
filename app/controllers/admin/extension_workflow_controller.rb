# frozen_string_literal: true

class Admin::ExtensionWorkflowController < Admin::ApplicationController
  DOC_PATH = Rails.root.join("docs/extension-workflow.md")
  HEALTH_WINDOW = 7.days
  CAPTURE_HEALTH_COLUMNS = [
    "properties->>'provider' AS provider",
    "COUNT(*) AS captures",
    "ROUND(AVG((properties->>'field_count')::numeric), 1) AS avg_fields",
    "COUNT(*) FILTER (WHERE properties->>'extraction_method' = 'json_ld') AS json_ld_count",
    "COUNT(*) FILTER (WHERE properties->>'extraction_confidence' = 'low') AS low_confidence_count"
  ].join(", ").freeze

  def show
    @doc = File.read(DOC_PATH)
    @capture_health = capture_health
  end

  private

  # Per-provider rollup of the "Captured Lead" Ahoy event (see
  # Api::LeadsController#track_capture) -- aggregate extraction quality
  # across a board's recent captures, distinct from ExtractionRuleObservation
  # which tracks one field's selector history. A provider with a falling
  # avg_fields or rising low-confidence share is a board that needs
  # attention (redesign drift), even if no single field has been re-taught.
  def capture_health
    Ahoy::Event.where(name: "Captured Lead", time: HEALTH_WINDOW.ago..)
               .group("properties->>'provider'")
               .select(CAPTURE_HEALTH_COLUMNS)
               .order(captures: :desc)
  end
end
