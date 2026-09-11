# frozen_string_literal: true

# == Schema Information
#
# Table name: question_archetypes
#
#  id               :bigint           not null, primary key
#  canonical_prompt :string           not null
#  label            :string           not null
#  notes            :text
#  question_kind    :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  merged_into_id   :bigint
#
# Indexes
#
#  index_question_archetypes_on_merged_into_id  (merged_into_id)
#  index_question_archetypes_on_question_kind   (question_kind)
#
# Foreign Keys
#
#  fk_rails_...  (merged_into_id => question_archetypes.id)
#
FactoryBot.define do
  factory :question_archetype do
    sequence(:label) { |n| "Archetype #{n}" }
    canonical_prompt { "why do you want to work here" }
    question_kind { "motivation" }
  end
end
