# frozen_string_literal: true

module Notifications
  class RequestFaraday < ApplicationRecord
    enum status: {
      pending: 0,
      active: 1,
      archive: 2
    }, _prefix: true
  end
end

# Notifications::RequestFaraday.last.payload.dig('response', 'body', 'rss', 'channel', 'item')

# == Schema Information
# Schema version: 20210709233739
#
# Table name: notifications_request_faradays
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null, indexed
#  status     :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
