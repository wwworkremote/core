# frozen_string_literal: true

class Domain < ApplicationRecord
  has_many :target_domains, -> { readonly }, dependent: :restrict_with_error, inverse_of: :domains
  has_many :job_postings, -> { readonly }, through: :target_domains

  # rails_admin do
  #   label 'Domain'
  #   label_plural 'Domains'

  #   list do
  #     field :name do
  #       column_width 300
  #     end
  #     field :root do
  #       label 'Root?'
  #       formatted_value { bindings[:object].id == bindings[:object].root_domain_id ? 'T' : 'F' }
  #     end
  #   end
  # end
end

# == Schema Information
#
# Table name: domains
# Database name: primary
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
