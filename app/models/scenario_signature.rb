# frozen_string_literal: true

# One externally-observed identity encountered during a Scenario's capture
# (a LinkedIn job id, a Greenhouse job_post_id, a session cookie...).
# Append-only, same convention ApplicationFieldMapping already uses for its
# own history -- a correction is a new row, not an overwrite, so later
# tooling can see whether an id changed mid-flow rather than only ever
# seeing the last one. #kind is a free string, not a fixed enum: new
# providers introduce new kinds. See docs/architecture/signature-registry.md.
# == Schema Information
#
# Table name: scenario_signatures
#
#  id                :bigint           not null, primary key
#  first_observed_at :datetime         not null
#  kind              :string           not null
#  step              :string
#  value             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  scenario_id       :bigint           not null
#
# Indexes
#
#  idx_scenario_signatures_uniq              (scenario_id,kind,value) UNIQUE
#  index_scenario_signatures_on_scenario_id  (scenario_id)
#
# Foreign Keys
#
#  fk_rails_...  (scenario_id => scenarios.id)
#
class ScenarioSignature < ApplicationRecord
  belongs_to :scenario

  validates :kind, :value, :first_observed_at, presence: true
  validates :value, uniqueness: { scope: %i[scenario_id kind] }
end
