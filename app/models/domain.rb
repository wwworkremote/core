# frozen_string_literal: true

class Domain < ApplicationRecord
  def root?
    id == root_domain_id
  end

  has_many :target_domains, dependent: :destroy
  has_many :job_postings, through: :target_domains
end

# == Schema Information
#
# Table name: domains
#
#  id             :bigint           not null, primary key
#  name           :citext           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  root_domain_id :bigint
#
# Indexes
#
#  index_domains_on_name  (name) UNIQUE
#
