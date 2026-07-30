# frozen_string_literal: true

# == Schema Information
#
# Table name: skills
#
#  id          :bigint           not null, primary key
#  category    :string
#  description :text
#  embedding   :vector(3584)
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_skills_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :skill do
    sequence(:name) { |n| "Skill #{n}" }
  end
end
