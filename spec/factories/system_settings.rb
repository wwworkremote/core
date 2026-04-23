# frozen_string_literal: true

# == Schema Information
#
# Table name: system_settings
#
#  id         :bigint           not null, primary key
#  key        :string
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_system_settings_on_key  (key)
#
FactoryBot.define do
  factory :system_setting do
    key { 'MyString' }
    value { 'MyString' }
  end
end
