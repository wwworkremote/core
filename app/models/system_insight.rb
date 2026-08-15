# frozen_string_literal: true

# == Schema Information
#
# Table name: system_insights
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE)
#  context     :text
#  embedding   :vector(768)
#  file_path   :string
#  line_number :integer
#  message     :text
#  severity    :integer
#  tool        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_system_insights_on_active          (active)
#  index_system_insights_on_embedding_hnsw  (((embedding)::halfvec(768)) halfvec_cosine_ops) USING hnsw
#  index_system_insights_on_file_path       (file_path)
#
class SystemInsight < ApplicationRecord
  has_neighbors :embedding # For vector similarity searches

  enum :tool, {
    rubocop: 0,
    reek: 1,
    brakeman: 2,
    rails_best_practices: 3,
    flay: 4,
    packwerk: 5
  }

  enum :severity, {
    advisory: 0,
    warning: 1,
    critical: 2
  }

  validates :message, presence: true
  validates :tool, presence: true

  scope :active, -> { where(active: true) }

  after_create_commit :enqueue_embedding

  def self.for_file(path)
    where(file_path: path, active: true)
  end

  private

  def enqueue_embedding
    Quality::InsightEmbeddingJob.perform_later(id)
  end
end
