# == Schema Information
#
# Table name: job_boards_sources
#
#  id         :bigint           not null, primary key
#  aasm_state :string
#  data       :jsonb            not null
#  name       :string           not null
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_job_boards_sources_on_slug  (slug) UNIQUE
#
class JobBoards::Source < ApplicationRecord
end
