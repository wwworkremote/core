# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_companies_on_slug  (slug)
#
FactoryBot.define do
  factory :company do
    name { "MyString" }
    slug { "MyString" }
    status { "MyString" }
  end
end
