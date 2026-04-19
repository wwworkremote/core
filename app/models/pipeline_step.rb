# == Schema Information
#
# Table name: pipeline_steps
#
#  id             :bigint           not null, primary key
#  notes          :text
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#
# Indexes
#
#  index_pipeline_steps_on_job_posting_id  (job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#
class PipelineStep < ApplicationRecord
  belongs_to :job_posting
end
