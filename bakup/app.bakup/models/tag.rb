# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId

  def root?
    id == root_tag_id
  end

  scope :roots, -> { where('id = root_tag_id') }

  friendly_id :name, use: :slugged

  def normalize_friendly_id(input)
    input.to_s.to_slug.normalize.to_s
  end
end

# == Schema Information
#
# Table name: tags
#
#  id          :bigint           not null, primary key
#  name        :citext           not null
#  slug        :citext           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  root_tag_id :integer
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#  index_tags_on_slug  (slug) UNIQUE
#
