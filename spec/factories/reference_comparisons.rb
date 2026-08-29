# frozen_string_literal: true

# == Schema Information
#
# Table name: reference_comparisons
#
#  id                       :bigint           not null, primary key
#  comparison_rules_version :string           not null
#  coverage                 :jsonb            not null
#  error                    :string
#  outcome                  :string           not null
#  provider                 :string           not null
#  ran_at                   :datetime         not null
#  trigger                  :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  guided_session_id        :bigint           not null
#  reference_scenario_id    :bigint
#  scenario_id              :bigint           not null
#
# Indexes
#
#  idx_on_provider_reference_scenario_id_e9d8e683d2      (provider,reference_scenario_id)
#  index_reference_comparisons_on_guided_session_id      (guided_session_id)
#  index_reference_comparisons_on_reference_scenario_id  (reference_scenario_id)
#  index_reference_comparisons_on_scenario_id            (scenario_id)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#  fk_rails_...  (reference_scenario_id => reference_scenarios.id)
#  fk_rails_...  (scenario_id => scenarios.id)
#
FactoryBot.define do
  factory :reference_comparison do
    guided_session { GuidedSession.create!(source_url: "https://wwworkremote.localhost/sandbox/postings/1") }
    scenario
    provider { "greenhouse" }
    comparison_rules_version { Scenarios::ComparisonRules::VERSION }
    outcome { "ok" }
    trigger { "automatic" }
  end

  factory :comparison_finding do
    reference_comparison
    category { "drift" }
    dimension { "field" }
    sequence(:locator) { |n| "field:field_#{n}" }
  end

  factory :finding_disposition do
    comparison_finding
    value { "unresolved" }
    reviewer { "mike" }
  end
end
