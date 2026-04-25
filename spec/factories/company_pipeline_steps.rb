# frozen_string_literal: true

# == Schema Information
#
# Table name: company_pipeline_steps
#
#  id         :bigint           not null, primary key
#  link       :string
#  note       :text
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_company_pipeline_steps_on_company_id  (company_id)
#  index_company_pipeline_steps_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :company_pipeline_step do
    company { nil }
    status { "MyString" }
    note { "MyText" }
    link { "MyString" }
  end
end
