# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string           default(""), not null
#  name            :string           not null
#  password_digest :string
#  slug            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_slug   (slug) UNIQUE
#
class User < ApplicationRecord
  has_secure_password

  has_one :career_profile, dependent: :destroy
  has_many :user_job_postings, dependent: :destroy
  has_many :job_postings, through: :user_job_postings
  has_many :pipeline_steps, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :company_pipeline_steps, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :set_defaults

  def set_defaults
    self.name ||= "User #{SecureRandom.hex(4)}"
    self.slug ||= SecureRandom.hex(8)
  end
end
