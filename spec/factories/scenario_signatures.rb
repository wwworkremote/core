# frozen_string_literal: true

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
FactoryBot.define do
  factory :scenario_signature do
    scenario
    kind { "job_id" }
    sequence(:value) { |n| "value-#{n}" }
    first_observed_at { Time.current }
  end
end
