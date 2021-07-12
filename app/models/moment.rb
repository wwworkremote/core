# frozen_string_literal: true

class Moment < ApplicationRecord
  enum cleek: { messages: 1, sources: 2, tags: 3 }, _prefix: true

  def self.snapshot!
    cleeks = Cleek.all.to_a
    cleeks.each do |cleek|
      Moment.create(
        cleek: cleek.id,
        cleeked_at: cleek.cleeked_at,
        lbound: cleek.lbound,
        lbound_week: cleek.lbound_week,
        lbound_week_value: cleek.lbound_week_value,
        lbound_day: cleek.lbound_day,
        lbound_day_value: cleek.lbound_day_value,
        lbound_hour: cleek.lbound_hour,
        lbound_hour_value: cleek.lbound_hour_value,
        rbound: cleek.rbound,
        value: cleek.value
      )
    end
  end
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
