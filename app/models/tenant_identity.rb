# frozen_string_literal: true

# Per-employer instance within a provider -- ADR 010 §4 and
# docs/architecture/signature-registry.md "Decided". Records only that an
# account/tenant exists at `identifier` on `provider`; never credentials.
# The next capture at the same employer looks this up before assuming
# sense-making from zero.
# == Schema Information
#
# Table name: tenant_identities
#
#  id         :bigint           not null, primary key
#  identifier :string           not null
#  provider   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tenant_identities_on_provider_and_identifier  (provider,identifier) UNIQUE
#
class TenantIdentity < ApplicationRecord
  has_many :scenarios, dependent: :nullify

  validates :provider, :identifier, presence: true
  validates :identifier, uniqueness: { scope: :provider }

  # Find-or-create for one (provider, employer) pair. nil identifier -> nil
  # (a capture we can't attribute to an employer stays unattributed).
  # SELECT-then-INSERT: the DB unique index is the real guard; a lost race
  # here would raise, which is fine for this single-operator app.
  def self.for(provider:, identifier:)
    return nil if provider.blank? || identifier.blank?

    find_or_create_by!(provider: provider, identifier: identifier)
  end
end
