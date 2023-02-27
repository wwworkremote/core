# == Schema Information
#
# Table name: job_boards_queries
#
#  id         :bigint           not null, primary key
#  aasm_state :string
#  data       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  source_id  :integer          not null
#
class JobBoards::Query < ApplicationRecord
end
