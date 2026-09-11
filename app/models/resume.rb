# frozen_string_literal: true

# == Schema Information
#
# Table name: resumes
#
#  id                :bigint           not null, primary key
#  content           :jsonb            not null
#  embedding         :vector(768)
#  imported_from_url :string
#  name              :string           not null
#  status            :string           default("inactive"), not null
#  version           :integer          default(1), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  parent_id         :bigint
#  user_id           :bigint           not null
#
# Indexes
#
#  index_resumes_on_embedding_hnsw                (((embedding)::halfvec(768)) halfvec_cosine_ops) USING hnsw
#  index_resumes_on_parent_id                     (parent_id)
#  index_resumes_on_user_id                       (user_id)
#  index_resumes_on_user_id_and_name_and_version  (user_id,name,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Resume < ApplicationRecord
  belongs_to :user
  belongs_to :parent, class_name: "Resume", optional: true, inverse_of: :children
  has_many :children, class_name: "Resume", foreign_key: "parent_id", inverse_of: :parent, dependent: :nullify

  has_many :resume_skills, dependent: :destroy
  has_many :skills, through: :resume_skills

  has_many :job_searches, dependent: :nullify

  validates :name, presence: true
  validates :version, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :version, uniqueness: { scope: %i[user_id name] }

  has_neighbors :embedding

  before_save :generate_embedding, if: :content_changed?

  def to_text_for_embedding
    ResumeExportService.new(self).to_text.truncate(3000)
  end

  private

  def generate_embedding
    self.embedding = VectorIntelligence.embed(to_text_for_embedding)
  end

  enum :status, {
    inactive: "inactive",
    active: "active",
    archived: "archived"
  }, default: :inactive

  # Content structure example:
  # {
  #   summary: "...",
  #   experience: [{ company: "...", role: "...", description: "...", start_date: "...", end_date: "..." }],
  #   education: [...],
  #   projects: [...]
  # }
end
