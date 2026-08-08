# frozen_string_literal: true

# == Schema Information
#
# Table name: resumes
#
#  id                :bigint           not null, primary key
#  content           :jsonb            not null
#  embedding         :vector(3584)
#  imported_from_url :string
#  name              :string           not null
#  status            :string           default("inactive"), not null
#  version           :integer          default(1), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :bigint
#  user_id           :bigint           not null
#
# Indexes
#
#  index_resumes_on_embedding_hnsw                (((embedding)::halfvec(3584)) halfvec_cosine_ops) USING hnsw
#  index_resumes_on_parent_id                     (parent_id)
#  index_resumes_on_user_id                       (user_id)
#  index_resumes_on_user_id_and_name_and_version  (user_id,name,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :resume do
    user
    sequence(:name) { |n| "Resume #{n}" }
    version { 1 }
    content { {} }
  end
end
