# frozen_string_literal: true

# == Schema Information
#
# Table name: work_experiences
#
#  id                :bigint           not null, primary key
#  action            :text
#  company_name      :string
#  context           :text
#  description       :text
#  employment_type   :string
#  end_date          :date
#  impact            :text
#  location          :string
#  scope             :jsonb
#  start_date        :date
#  summary           :text
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  career_profile_id :bigint           not null
#  external_id       :string
#
# Indexes
#
#  index_work_experiences_on_career_profile_id  (career_profile_id)
#  index_work_experiences_on_external_id        (external_id)
#
# Foreign Keys
#
#  fk_rails_...  (career_profile_id => career_profiles.id)
#
FactoryBot.define do
  factory :work_experience do
    career_profile { nil }
    company_name { 'MyString' }
    location { 'MyString' }
    title { 'MyString' }
    employment_type { 'MyString' }
    start_date { '2026-04-19' }
    end_date { '2026-04-19' }
    context { 'MyText' }
    description { 'MyText' }
    summary { 'MyText' }
    action { 'MyText' }
    impact { 'MyText' }
    scope { '' }
  end
end
