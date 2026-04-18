# == Schema Information
#
# Table name: job_boards_queries
# Database name: primary
#
#  id         :bigint           not null, primary key
#  aasm_state :string
#  data       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  source_id  :integer          not null
#
# Indexes
#
#  index_job_boards_queries_on_source_id  (source_id)
#
class JobBoards::Query < ApplicationRecord
  belongs_to :job_boards_source, class_name: 'JobBoards::Source', foreign_key: 'source_id'
  has_many :job_boards_documents, class_name: 'JobBoards::Document', foreign_key: 'job_boards_query_id', dependent: :destroy
end
