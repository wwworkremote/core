# frozen_string_literal: true

# == Schema Information
#
# Table name: contacts
#
#  id                :bigint           not null, primary key
#  email             :string
#  name              :string
#  phone             :string
#  relationship_type :string
#  role              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  job_posting_id    :bigint           not null
#  user_id           :bigint
#
# Indexes
#
#  index_contacts_on_job_posting_id  (job_posting_id)
#  index_contacts_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :contact do
    name { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    role { "MyString" }
    relationship_type { "MyString" }
    job_posting { nil }
  end
end
