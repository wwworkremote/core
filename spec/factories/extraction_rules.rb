# frozen_string_literal: true

# == Schema Information
#
# Table name: extraction_rules
#
#  id          :bigint           not null, primary key
#  field_name  :string           not null
#  provider    :string           not null
#  sample_html :text
#  selector    :string           not null
#  source_url  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_extraction_rules_on_provider_and_field_name  (provider,field_name) UNIQUE
#
FactoryBot.define do
  factory :extraction_rule do
    provider { "linkedin" }
    sequence(:field_name) { |n| "field_#{n}" }
    selector { "h1.job-title" }
  end
end
