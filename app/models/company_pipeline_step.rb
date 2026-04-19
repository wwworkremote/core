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
#
# Indexes
#
#  index_company_pipeline_steps_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class CompanyPipelineStep < ApplicationRecord
  belongs_to :company
end
