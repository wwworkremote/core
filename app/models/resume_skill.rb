# frozen_string_literal: true

# == Schema Information
#
# Table name: resume_skills
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  resume_id  :bigint           not null
#  skill_id   :bigint           not null
#
# Indexes
#
#  index_resume_skills_on_resume_id               (resume_id)
#  index_resume_skills_on_resume_id_and_skill_id  (resume_id,skill_id) UNIQUE
#  index_resume_skills_on_skill_id                (skill_id)
#
# Foreign Keys
#
#  fk_rails_...  (resume_id => resumes.id)
#  fk_rails_...  (skill_id => skills.id)
#
class ResumeSkill < ApplicationRecord
  belongs_to :resume
  belongs_to :skill

  validates :resume_id, uniqueness: { scope: :skill_id }
end
