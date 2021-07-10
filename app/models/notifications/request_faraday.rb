# frozen_string_literal: true

module Notifications
  class RequestFaraday < ApplicationRecord
    enum status: {
      pending: 0,
      processed: 1
    }, _prefix: true

    has_many :messages, inverse_of: :requests, dependent: :nullify, foreign_key: 'notifications_request_faradays_id'
  end
end

# == Schema Information
# Schema version: 20210710001701
#
# Table name: notifications_request_faradays
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null, indexed
#  status     :integer          default("pending")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
