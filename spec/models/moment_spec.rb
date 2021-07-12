require 'rails_helper'

RSpec.describe Moment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
# Schema version: 20210712004243
#
# Table name: moments
#
#  id                :bigint           not null, primary key
#  cleek             :integer
#  cleeked_at        :datetime
#  lbound            :datetime
#  lbound_day        :datetime
#  lbound_day_value  :integer
#  lbound_hour       :datetime
#  lbound_hour_value :integer
#  lbound_week       :datetime
#  lbound_week_value :integer
#  rbound            :datetime
#  value             :integer
#  created_at        :datetime         not null
#
