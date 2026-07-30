# frozen_string_literal: true

# == Schema Information
#
# Table name: discovery_links
#
#  id            :bigint           not null, primary key
#  board_name    :string
#  error_message :text
#  status        :string
#  url           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_discovery_links_on_url  (url) UNIQUE
#
class DiscoveryLink < ApplicationRecord
  validates :url, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending processing processed error] }, allow_nil: true

  after_create_commit do
    broadcast_prepend_to(
      "admin_live_feed",
      target: "live_ingestion",
      partial: "admin/dashboard/live_feed/discovery_link",
      locals: { discovery_link: self }
    )
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id board_name url status error_message created_at updated_at]
  end
end
