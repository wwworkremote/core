# frozen_string_literal: true

class Source < ApplicationRecord
  range_partition_by { '(created_at::date)' }

  self.primary_key = :id, :created_at
  self.implicit_order_column = :created_at

  has_many :job_postings, dependent: :nullify

  def self.maintenance
    partitions = [
      Time.zone.today.prev_month(12),
      Time.zone.today.prev_month(11),
      Time.zone.today.prev_month(10),
      Time.zone.today.prev_month(9),
      Time.zone.today.prev_month(8),
      Time.zone.today.prev_month(7),
      Time.zone.today.prev_month(6),
      Time.zone.today.prev_month(5),
      Time.zone.today.prev_month(4),
      Time.zone.today.prev_month(3),
      Time.zone.today.prev_month(2),
      Time.zone.today.prev_month(1),
      Time.zone.today,
      Time.zone.today.next_month(1),
      Time.zone.today.next_month(2),
      Time.zone.today.next_month(3)
    ]

    partitions.each do |day|
      name = Source.partition_name_for(day)
      next if ActiveRecord::Base.connection.table_exists?(name)

      Source.create_partition(
        name: name,
        start_range: day.beginning_of_month,
        end_range: day.next_month.beginning_of_month
      )
    end
  end

  def self.partition_name_for(day)
    "sources_y#{day.year}_m#{day.month.to_s.rjust(2, '0')}"
  end

  def payload_url
    payload&.send(:[], 'url')
  end
end

# == Schema Information
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
# Indexes
#
#  index_sources_on_origin_id  (origin_id)
#  index_sources_on_signature  (signature) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (origin_id => origins.id)
#
