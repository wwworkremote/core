# frozen_string_literal: true

# == Schema Information
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
# Indexes
#
#  index_sources_on_event      (event) USING gin
#  index_sources_on_origin_id  (origin_id)
#  index_sources_on_payload    (payload) USING gin
#  index_sources_on_signature  (signature) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (origin_id => origins.id)
#
FactoryBot.define do
  factory :source do
    sequence(:signature) { |n| "source-#{n}" }
  end
end
