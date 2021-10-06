# frozen_string_literal: true

class DomainHierarchy < ApplicationRecord
  self.primary_key = :id

  def subdomain_names
    subdomains.values
  end

  def subdomain_ids
    subdomains.keys.map(&:to_i)
  end

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: false)
  end
end

# == Schema Information
#
# Table name: domain_hierarchies
#
#  id              :bigint           primary key
#  name            :citext
#  subdomain_count :bigint
#  subdomains      :jsonb
#
# Indexes
#
#  index_domain_hierarchies_on_id  (id) UNIQUE
#
