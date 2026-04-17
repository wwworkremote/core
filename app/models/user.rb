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

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :set_defaults

  def set_defaults
    self.name ||= 'Admin'
    self.slug ||= SecureRandom.hex(8)
  end
end
