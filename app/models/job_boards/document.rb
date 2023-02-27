# == Schema Information
#
# Table name: job_boards_documents
#
#  id                  :uuid             not null, primary key
#  aasm_state          :string
#  document            :text             default(""), not null
#  signature           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  job_boards_query_id :integer          not null
#  source_id           :integer          not null
#
# Indexes
#
#  index_job_boards_documents_on_signature  (signature) UNIQUE
#
class JobBoards::Document < ApplicationRecord
end
