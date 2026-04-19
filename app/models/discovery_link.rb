# == Schema Information
#
# Table name: discovery_links
#
#  id         :bigint           not null, primary key
#  board_name :string
#  status     :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_discovery_links_on_url  (url)
#
class DiscoveryLink < ApplicationRecord
end
