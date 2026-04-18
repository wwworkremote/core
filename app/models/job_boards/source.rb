# == Schema Information
#
# Table name: job_boards_sources
# Database name: primary
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
  has_many :job_boards_queries, class_name: 'JobBoards::Query', foreign_key: 'source_id', dependent: :destroy
  has_many :job_boards_documents, class_name: 'JobBoards::Document', foreign_key: 'source_id', dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name slug created_at updated_at]
  end
end
