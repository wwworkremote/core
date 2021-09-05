# frozen_string_literal: true

class Origin < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged
end
