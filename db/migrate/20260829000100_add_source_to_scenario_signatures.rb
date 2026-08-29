# frozen_string_literal: true

# Value-free provenance breadcrumb linking a normalized signature back to the
# GuidedSessionEvent it was materialized from (Scenarios::GuidedCapture, ADR 009).
# NULL for signatures captured through the HAR/DOM text path.
class AddSourceToScenarioSignatures < ActiveRecord::Migration[8.1]
  def change
    add_column :scenario_signatures, :source, :jsonb
  end
end
