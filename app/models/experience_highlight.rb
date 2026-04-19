# == Schema Information
#
# Table name: experience_highlights
#
#  id                 :bigint           not null, primary key
#  label              :string
#  text               :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  work_experience_id :bigint           not null
#
# Indexes
#
#  index_experience_highlights_on_work_experience_id  (work_experience_id)
#
# Foreign Keys
#
#  fk_rails_...  (work_experience_id => work_experiences.id)
#
class ExperienceHighlight < ApplicationRecord
  belongs_to :work_experience
end
