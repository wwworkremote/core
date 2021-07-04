# frozen_string_literal: true

module Notifications
  class RequestFaraday < ApplicationRecord
    # jsonb_accessor :event, end: :float, name: :string, time: :float, cpu_time_start: :float, transaction_id: :string, cpu_time_finish: :float, allocation_count_start: :integer, allocation_count_finish: :integer

    def rss?
      return false if payload.dig('response', 'body').blank?
      return false if payload.dig('response', 'body').is_a?(Array)

      payload.dig('response', 'body', 'rss', 'channel', 'item').present?
    end
  end
end

# Notifications::RequestFaraday.last.payload.dig('response', 'body', 'rss', 'channel', 'item')

# == Schema Information
# Schema version: 20210703173154
#
# Table name: notifications_request_faradays
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null, indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
