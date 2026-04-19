# == Schema Information
#
# Table name: career_profiles
#
#  id               :bigint           not null, primary key
#  experience_level :string
#  goals            :text
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
  has_many :job_experiences, dependent: :destroy
  accepts_nested_attributes_for :job_experiences, allow_destroy: true
end
