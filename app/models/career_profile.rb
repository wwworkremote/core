# frozen_string_literal: true

# == Schema Information
#
# Table name: career_profiles
#
#  id               :bigint           not null, primary key
#  contact_info     :jsonb
#  embedding        :vector(3584)
#  experience_level :string
#  github_context   :jsonb
#  github_url       :string
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
  has_many :job_experiences, dependent: :destroy
  has_many :experience_highlights, through: :work_experiences

  has_many_attached :resumes

  has_neighbors :embedding

  validates :github_url,
            format: {
              with: %r{\Ahttps?://(www\.)?github\.com/[a-zA-Z0-9_-]+\z},
              message: "must be a valid GitHub URL"
            },
            allow_blank: true

  accepts_nested_attributes_for :work_experiences, allow_destroy: true
end
