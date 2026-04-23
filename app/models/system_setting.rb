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
class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.paused?
    find_by(key: 'pipelines_paused')&.value == 'true'
  end

  def self.pause!
    find_or_create_by!(key: 'pipelines_paused').update!(value: 'true')
  end

  def self.resume!
    find_or_create_by!(key: 'pipelines_paused').update!(value: 'false')
  end
end
