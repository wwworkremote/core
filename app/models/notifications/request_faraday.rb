# frozen_string_literal: true

module Notifications
  class RequestFaraday < ApplicationRecord
    # jsonb_accessor :event, title: :string, external_id: :integer, reviewed_at: :datetime
  end
end

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
