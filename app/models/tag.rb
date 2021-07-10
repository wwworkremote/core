# frozen_string_literal: true

class Tag < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
  has_many :tag_aliases, dependent: :nullify

  after_commit :create_tag_alias, on: :create

  def create_tag_alias
    tag_aliases.create(name: name)
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
    Rails.logger.debug { [e.message, name] }
  end
end

# == Schema Information
# Schema version: 20210710142759
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string           indexed
#  slug       :string           indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
