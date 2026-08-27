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
class Scenario < ApplicationRecord
  has_secure_token :scenario_token

  belongs_to :user_job_posting, optional: true
  has_many :scenario_signatures, dependent: :destroy

  validates :provider, :started_at, presence: true
end
