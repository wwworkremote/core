# == Schema Information
#
# Table name: career_profiles
#
#  id               :bigint           not null, primary key
#  experience_level :string
#  goals            :text
#  resume_text      :text
#  skills           :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_career_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :career_profile do
    user { nil }
    resume_text { "MyText" }
    goals { "MyText" }
    skills { "MyText" }
    experience_level { "MyString" }
  end
end
