# frozen_string_literal: true

require "rails_helper"

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
RSpec.describe Scenario do
  describe "validations" do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:started_at) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user_job_posting).optional }
    it { is_expected.to have_many(:scenario_signatures).dependent(:destroy) }
  end

  describe "#scenario_token" do
    it "is generated automatically on create, independent of application_trace_id" do
      scenario = create(:scenario)
      expect(scenario.scenario_token).to be_present
    end

    it "is unique" do
      first = create(:scenario)
      second = create(:scenario)
      expect(second.scenario_token).not_to eq(first.scenario_token)
    end

    it "exists even when the scenario never produces a real application" do
      scenario = create(:scenario, user_job_posting: nil)
      expect(scenario.scenario_token).to be_present
      expect(scenario.user_job_posting).to be_nil
    end
  end

  it "can be linked to a real tracked application" do
    ujp = create(:user_job_posting)
    scenario = create(:scenario, user_job_posting: ujp)
    expect(scenario.user_job_posting).to eq(ujp)
  end
end
