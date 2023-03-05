# frozen_string_literal: true

# == Schema Information
#
# Table name: hacker_news_v0_jobstories
#
#  id         :integer          not null
#  by         :string
#  data       :jsonb            not null
#  score      :integer
#  time       :integer
#  title      :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hacker_news_v0_jobstories_on_id  (id) UNIQUE
#
module HackerNews
  module V0
    class Jobstory < ApplicationRecord
      self.primary_key = :id
    end
  end
end
