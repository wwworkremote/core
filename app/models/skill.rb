# frozen_string_literal: true

# == Schema Information
#
# Table name: skills
#
#  id          :bigint           not null, primary key
#  category    :string
#  description :text
#  embedding   :vector(3584)
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_skills_on_name  (name) UNIQUE
#
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
