# frozen_string_literal: true

# A deliberately recorded session -- Mike consciously starting a capture,
# whether or not it results in a real application. Scoped to that case only:
# the routine LinkedIn/Greenhouse/Indeed HAR backfills run through
# Applications::RowImporter and never touch this table. See
# docs/architecture/signature-registry.md.
#
# #scenario_token is a super-identifier independent of
# UserJobPosting#application_trace_id -- a Scenario that never produces a
# real application still has a complete token; application_trace_id never
# would, since it only exists once a real application does.
#
# #resume_persona_id (nullable, mirrors UserJobPosting#resume_persona_id) --
# a persona-driven divergence in a captured session (different answer
# content, possibly a different ATS branch) must not be misread later as
# provider drift or an incomplete Reference Scenario. A verification-only
# capture against the sandbox provider may legitimately have none.
# == Schema Information
#
# Table name: scenarios
#
#  id                   :bigint           not null, primary key
#  guided_session_token :string
#  provider             :string           not null
#  scenario_token       :string           not null
#  started_at           :datetime         not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  resume_persona_id    :string
#  tenant_identity_id   :bigint
#  user_job_posting_id  :bigint
#
# Indexes
#
#  index_scenarios_on_guided_session_token  (guided_session_token)
#  index_scenarios_on_scenario_token        (scenario_token) UNIQUE
#  index_scenarios_on_tenant_identity_id    (tenant_identity_id)
#  index_scenarios_on_user_job_posting_id   (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (tenant_identity_id => tenant_identities.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
class Scenario < ApplicationRecord
  has_secure_token :scenario_token

  belongs_to :user_job_posting, optional: true
  # Per-employer instance this capture belongs to (ADR 010 §4). Optional --
  # a verification-only capture may not be attributable to an employer.
  belongs_to :tenant_identity, optional: true
  has_many :scenario_signatures, dependent: :destroy
  has_one :reference_scenario, dependent: :restrict_with_error

  validates :provider, :started_at, presence: true
end
