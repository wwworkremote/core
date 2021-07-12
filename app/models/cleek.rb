# frozen_string_literal: true

class Cleek < ApplicationRecord
  def readonly?
    true
  end
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
