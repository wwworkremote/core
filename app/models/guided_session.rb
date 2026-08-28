# frozen_string_literal: true

# A durable supervised lap through the job-posting-to-application pump track.
# The initial intake slice records where the lap started and leaves all
# provider interaction behind the existing extension seam.
# == Schema Information
#
# Table name: guided_sessions
#
#  id                :bigint           not null, primary key
#  phase             :string           default("intake"), not null
#  playback_position :integer          default(0), not null
#  provider          :string           not null
#  session_token     :string           not null
#  source_url        :string           not null
#  started_at        :datetime         not null
#  status            :string           default("active"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_guided_sessions_on_session_token  (session_token) UNIQUE
#
class GuidedSession < ApplicationRecord
  PHASES = %w[intake resolution response_construction reorientation].freeze
  STATUSES = %w[active paused completed stopped].freeze

  has_secure_token :session_token
  has_many :guided_session_events, dependent: :destroy

  validates :source_url, :provider, :phase, :status, :started_at, presence: true
  validates :phase, inclusion: { in: PHASES }
  validates :status, inclusion: { in: STATUSES }
  validates :playback_position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :source_url_is_http

  before_validation :set_intake_attributes, on: :create

  private

  def set_intake_attributes
    self.attributes = default_attributes.merge(provider: provider || source_uri_host)
  end

  def default_attributes
    { started_at: started_at || Time.current,
      phase: phase || "intake",
      status: status || "active" }
  end

  def source_url_is_http
    uri = parsed_source_url
    return errors.add(:source_url, "must be a valid HTTP or HTTPS URL") unless uri&.host
    return if %w[http https].include?(uri.scheme)

    errors.add(:source_url, "must be a valid HTTP or HTTPS URL")
  end

  def parsed_source_url
    URI.parse(source_url.to_s)
  rescue URI::InvalidURIError
    nil
  end

  def source_uri_host
    parsed_source_url&.host&.downcase
  end
end
