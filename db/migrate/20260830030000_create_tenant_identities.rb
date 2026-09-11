# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
# Per-employer instance within a provider (ADR 010 §4 / signature-registry.md).
# "An account/tenant exists here" -- never credentials. A new capture at the
# same employer looks this up before assuming sense-making from zero.
class CreateTenantIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :tenant_identities do |t|
      t.string :provider, null: false
      t.string :identifier, null: false
      t.timestamps
    end
    add_index :tenant_identities, %i[provider identifier], unique: true

    safety_assured do
      add_reference :scenarios, :tenant_identity, null: true, foreign_key: true, index: true
    end
  end
end
# rubocop:enable Metrics/MethodLength
