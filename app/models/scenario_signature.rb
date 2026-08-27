# frozen_string_literal: true

# One externally-observed identity encountered during a Scenario's capture
# (a LinkedIn job id, a Greenhouse job_post_id, a session cookie...).
# Append-only, same convention ApplicationFieldMapping already uses for its
# own history -- a correction is a new row, not an overwrite, so later
# tooling can see whether an id changed mid-flow rather than only ever
# seeing the last one. #kind is a free string, not a fixed enum: new
# providers introduce new kinds. See docs/architecture/signature-registry.md.
class ScenarioSignature < ApplicationRecord
  belongs_to :scenario

  validates :kind, :value, :first_observed_at, presence: true
  validates :value, uniqueness: { scope: %i[scenario_id kind] }
end
