# == Schema Information
#
# Table name: job_experiences
#
#  id                :bigint           not null, primary key
#  company           :string
#  current           :boolean
#  description       :text
#  end_date          :date
#  start_date        :date
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  career_profile_id :bigint           not null
#
# Indexes
#
#  index_job_experiences_on_career_profile_id  (career_profile_id)
#
# Foreign Keys
#
#  fk_rails_...  (career_profile_id => career_profiles.id)
#
FactoryBot.define do
  factory :job_experience do
    career_profile { nil }
    title { "MyString" }
    company { "MyString" }
    start_date { "2026-04-19" }
    end_date { "2026-04-19" }
    current { false }
    description { "MyText" }
  end
end
