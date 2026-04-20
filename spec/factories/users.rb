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
FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "test-#{SecureRandom.hex(4)}@example.com" }
    password { "password" }
    slug { SecureRandom.hex(8) }
  end
end
