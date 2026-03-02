# frozen_string_literal: true

class Origin < ApplicationRecord
  has_many :sources, dependent: :restrict_with_error
end
