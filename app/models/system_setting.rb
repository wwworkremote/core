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
#  index_system_settings_on_key  (key) UNIQUE
#
class SystemSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.paused?
    find_by(key: "pipelines_paused")&.value == "true"
  end

  def self.pause!
    find_or_create_by!(key: "pipelines_paused").update!(value: "true")
  end

  def self.resume!
    find_or_create_by!(key: "pipelines_paused").update!(value: "false")
  end

  def self.cancel_job!(job_id)
    ids = cancelled_job_ids
    ids << job_id.to_s
    find_or_create_by!(key: "cancelled_job_ids").update!(value: ids.uniq.join(","))
  end

  def self.job_cancelled?(job_id)
    cancelled_job_ids.include?(job_id.to_s)
  end

  def self.clear_job_cancellation!(job_id)
    ids = cancelled_job_ids
    ids.delete(job_id.to_s)
    find_or_create_by!(key: "cancelled_job_ids").update!(value: ids.join(","))
  end

  def self.cancelled_job_ids
    find_by(key: "cancelled_job_ids")&.value&.split(",") || []
  end
end
