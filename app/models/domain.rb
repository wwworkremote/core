# frozen_string_literal: true

class Domain < ApplicationRecord
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
