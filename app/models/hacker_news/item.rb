# frozen_string_literal: true

# == Schema Information
#
# Table name: hacker_news_items
#
#  id         :integer          not null, primary key
#  data       :jsonb
#  schema     :integer          default("unknown"), not null
#  state      :integer          default("pending"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hacker_news_items_on_id      (id) UNIQUE
#  index_hacker_news_items_on_schema  (schema)
#  index_hacker_news_items_on_state   (state)
#
class HackerNews::Item < ApplicationRecord
  self.primary_key = :id

  enum :schema, { unknown: 0, job: 1, story: 2, comment: 3, poll: 4, pollopt: 5 }
  enum :state, { pending: 0, ignore: 1 }
end
