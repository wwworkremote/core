# frozen_string_literal: true

# == Schema Information
#
# Table name: experience_highlights
#
#  id                 :bigint           not null, primary key
#  label              :string
#  text               :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  work_experience_id :bigint           not null
#
# Indexes
#
#  index_experience_highlights_on_work_experience_id  (work_experience_id)
#
# Foreign Keys
#
#  fk_rails_...  (work_experience_id => work_experiences.id)
#
FactoryBot.define do
  factory :experience_highlight do
    work_experience { nil }
    label { 'MyString' }
    text { 'MyText' }
  end
end
