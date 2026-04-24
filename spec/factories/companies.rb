# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id                 :bigint           not null, primary key
#  disposition        :string
#  glassdoor_data     :jsonb
#  ingestion_enabled  :boolean          default(TRUE), not null
#  name               :string
#  sentiment_score    :float
#  slug               :string
#  status             :string
#  toxic_culture_flag :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_companies_on_name  (name) UNIQUE
#  index_companies_on_slug  (slug)
#
FactoryBot.define do
  factory :company do
    name { "Company #{SecureRandom.hex(4)}" }
    slug { "company-#{SecureRandom.hex(4)}" }
    status { 'none' }
  end
end
