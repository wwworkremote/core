# frozen_string_literal: true

class Resume < ApplicationRecord
  belongs_to :user
  belongs_to :parent, class_name: "Resume", optional: true
  has_many :children, class_name: "Resume", foreign_key: "parent_id", dependent: :nullify

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
