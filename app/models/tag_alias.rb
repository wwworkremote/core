# frozen_string_literal: true

class TagAlias < ApplicationRecord
  belongs_to :tag, optional: true
end

# == Schema Information
#
# Table name: tag_aliases
#
#  id         :bigint           not null, primary key
#  tag_id     :bigint
#  name       :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
