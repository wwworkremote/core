# frozen_string_literal: true

# == Schema Information
#
# Table name: scenarios
#
#  id                  :bigint           not null, primary key
#  provider            :string           not null
#  scenario_token      :string           not null
#  started_at          :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  resume_persona_id   :string
#  user_job_posting_id :bigint
#
# Indexes
#
#  index_scenarios_on_scenario_token       (scenario_token) UNIQUE
#  index_scenarios_on_user_job_posting_id  (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
FactoryBot.define do
  factory :scenario do
    provider { "linkedin" }
    started_at { Time.current }
  end

  factory :reference_scenario do
    provider { scenario.provider }
    scenario
  end
end
