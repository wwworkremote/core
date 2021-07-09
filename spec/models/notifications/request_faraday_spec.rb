# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::RequestFaraday, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

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
