# == Schema Information
#
# Table name: career_profiles
#
#  id               :bigint           not null, primary key
#  contact_info     :jsonb
#  experience_level :string
#  goals            :text
#  location_info    :jsonb
#  resume_text      :text
#  skills           :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_career_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class CareerProfile < ApplicationRecord
  belongs_to :user
  has_many :work_experiences, dependent: :destroy
  has_many :experience_highlights, through: :work_experiences
  
  accepts_nested_attributes_for :work_experiences, allow_destroy: true
end
