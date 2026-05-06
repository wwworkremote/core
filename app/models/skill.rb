# frozen_string_literal: true

class Skill < ApplicationRecord
  has_many :resume_skills, dependent: :destroy
  has_many :resumes, through: :resume_skills

  validates :name, presence: true, uniqueness: true

  has_neighbors :embedding

  before_save :generate_embedding, if: :name_changed?

  private

  def generate_embedding
    self.embedding = VectorIntelligence.embed("#{name} #{category} #{description}")
  end
end
