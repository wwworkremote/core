# frozen_string_literal: true

# == Schema Information
#
# Table name: career_profiles
#
#  id               :bigint           not null, primary key
#  contact_info     :jsonb
#  embedding        :vector(3584)
#  experience_level :string
#  github_context   :jsonb
#  github_url       :string
#  goals            :text
#  location_info    :jsonb
#  resume_text      :text
#  skills           :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_career_profiles_on_embedding_hnsw  (((embedding)::halfvec(3584)) halfvec_cosine_ops) USING hnsw
#  index_career_profiles_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :career_profile do
    user
    resume_text { "MyText" }
    goals { "MyText" }
    skills { "MyText" }
    experience_level { "MyString" }
  end
end
