# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cleek, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
# Schema version: 20210712004243
#
# Table name: cleeks
#
#  id                :integer
#  cleeked_at        :datetime
#  lbound            :datetime
#  lbound_day        :datetime
#  lbound_day_value  :bigint
#  lbound_hour       :datetime
#  lbound_hour_value :bigint
#  lbound_week       :datetime
#  lbound_week_value :bigint
#  name              :text
#  rbound            :datetime
#  value             :bigint
#
