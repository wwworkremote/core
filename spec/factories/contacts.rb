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
#
# Indexes
#
#  index_contacts_on_job_posting_id  (job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
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
